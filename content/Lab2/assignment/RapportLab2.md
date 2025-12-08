# BDA Assignment 02 — Analyse de Texte avec Apache Spark

**Auteur**: PHAM DANG Son Alain et Imad GAMOUH | **Cours**: Big Data Analytics — ESIEE 2025-2026  


---

## 📋 Démarrage rapide

### Prérequis
- Python 3.10+, environnement conda
- Apache Spark 4.0.1
- OpenJDK 11+ ou Oracle JDK 11+
- 8 GB de RAM recommandé

### Installation et exécution

```bash
# 1. Activer l'environnement
conda activate bda-env

# 2. Lancer Jupyter
jupyter lab

# 3. Ouvrir BDA_Assignment02.ipynb et exécuter séquentiellement (Sections 1–8)

# 4. Surveiller l'interface Spark UI
# Ouvrir http://localhost:4040 pendant l'exécution
```

---

##  Structure du projet

```
Lab2/assignment/
├── README.md                           ← Vous êtes ici
├── ENV.md                              ← Configuration d'environnement & reproductibilité
├── BDA_Assignment02.ipynb              ← Notebook principal (exécutable)
│
├── data/
│   └── shakespeare.txt                 (3.6 MB, 122 458 lignes)
│
├── outputs/
│   ├── bigram_pairs_top_20.csv
│   ├── bigram_stripes_top_20.csv
│   ├── pmi_filtered.csv
│   ├── index_parquet/                  (Index inversé en Parquet)
│   ├── queries_and_results.md
│   ├── performance_pairs_vs_stripes.csv
│   ├── performance_shuffle_partitions.csv
│   └── performance_analysis.md
│
└── proof/
    ├── lab_metrics_log.csv             ← Métriques pour toutes les exécutions
    ├── explain_pairs_approach.txt
    ├── explain_stripes_approach.txt
    ├── plan_pmi.txt
    ├── plan_retrieval.txt
    └── screenshots/                    (Preuves Spark UI)
```

---

##  Vue d'ensemble de l'assignment

### Partie A : Fréquence relative de bigrammes (Pairs vs Stripes)

**Tâche** : Calculer la fréquence relative $f(w_i, w_{i+1}) / f(w_i, *)$ en utilisant deux patterns MapReduce.

**Approches** :
- **Pairs** : Émettre `((w_i, w_i+1), 1)` et `((w_i, *), 1)` → normaliser ( 3,5 s)
- **Stripes** : Émettre `(w_i → {w_i+1: count})` → normaliser (84,5 s)

**Gagnant** : **Pairs** (95,9% plus rapide) — agrégation précoce via `reduceByKey`

**Livrables** :
- `outputs/bigram_pairs_top_20.csv`
- `outputs/bigram_stripes_top_20.csv`
- `proof/explain_pairs_approach.txt`
- `proof/explain_stripes_approach.txt`

---

### Partie B : Information mutuelle ponctuelle (PMI)

**Tâche** : Calculer PMI(x, y) = log₁₀( P(x,y) / (P(x) × P(y)) ) pour les paires de mots co-apparaissant dans une ligne.

**Règles** :
- Premiers 40 tokens par ligne (prévient le biais des queues longues)
- Seuil de co-occurrence minimum : K (défaut = 10)
- Tokenization insensible à la casse, regex `[a-z]+`

**Formule** :
$$\text{PMI}(x, y) = \log_{10}\left(\frac{P(x, y)}{P(x) \cdot P(y)}\right)$$

**Résultats principaux** :
- `('i', 'am')` PMI ≈ 0,09 (phrase commune)
- `('romeo', 'juliet')` PMI ≈ 1,8 (co-apparition rare)

**Livrables** :
- `outputs/pmi_filtered.csv`
- `proof/plan_pmi.txt`

---

### Partie C : Index inversé et recherche booléenne

**Tâche** : Construire un index consultable à partir de documents synthétiques et exécuter des requêtes AND/OR.

**Définition de document** :
- 10 lignes consécutives = 1 document synthétique
- `doc_id = floor(line_number / 10)`
- Total : ~12 000 documents

**Schéma d'index** (Parquet) :
```
term: STRING
df: INT                           (document frequency)
postings: ARRAY<STRUCT>
  ├── doc_id: INT
  └── tf: INT                     (term frequency)
```

**Exemples de requêtes** :
1. `love AND heart` → 173 documents
2. `romeo AND juliet` → 16 documents
3. `fair OR beautiful` → 688 documents

**Logique de requête** :
- AND : Intersection des listes de postings
- OR : Union des listes de postings
- Scoring : Somme des valeurs TF × IDF

**Livrables** :
- `outputs/index_parquet/` (schéma indexé)
- `outputs/queries_and_results.md` (3+ résultats de requêtes)
- `proof/plan_retrieval.txt`

---

### Partie D : Étude de performance

**Tâche** : Comparer les designs Pairs vs Stripes et optimiser `shuffle.partitions`.

**Résultats clés** :

| Configuration | Durée (s) | Bigrammes | Surcharge shuffle |
|---|---|---|---|
| 8 partitions | 2,73 | 286 728 | Haute (peu de parallélisme) |
| 16 partitions | 2,32 | 286 728 | Équilibré |
| **32 partitions** | **1,93** | **286 728** | ** Optimal** |
| 64 partitions | 2,31 | 286 728 | Surcharge d'ordonnancement |

**Recommandation** : `spark.sql.shuffle.partitions = 32` pour le dataset Shakespeare de 3,6 MB

**Livrables** :
- `outputs/performance_pairs_vs_stripes.csv`
- `outputs/performance_shuffle_partitions.csv`
- `outputs/performance_analysis.md`
- `proof/lab_metrics_log.csv` (mis à jour avec métriques de shuffle)

---

## 📊 Preuves et métriques

### Métriques enregistrées (lab_metrics_log.csv)

```csv
run_id,task,timestamp,files_read,input_size_mb,shuffle_read_mb,shuffle_write_mb,duration_sec,notes
3,bigram_pairs,2025-11-19T18:20:23Z,1,3.6,4.0,4.0,3.0,"Job 79: reduceByKey (Stage 117)"
4,bigram_stripes,2025-11-20T07:28:06Z,1,3.6,2.2,2.2,9.0,"Job 22: groupByKey (Stage 29)"
5,pmi_filtered,2025-11-20T08:07:38Z,1,3.6,3.7,3.7,3.0,"Calcul PMI"
6,inverted_index,2025-11-20T08:40:27Z,1,3.6,5.3,5.3,7.6,"Construction d'index avec Parquet"
7,boolean_retrieval,2025-11-20T09:16:16Z,5,1.9,0.0,0.0,0.9,"Exécution de requêtes (partition pruning)"
```

### Interprétation EXPLAIN FORMATTED

**Approche Pairs** :
```
== Physical Plan ==
TakeOrderedAndProject(limit=20, orderBy=[count DESC])
+- *(1) Scan ExistingRDD[word1, word2, count]
```

**Interprétation** :
-  Agrégation précoce : `reduceByKey` pré-calcule les comptes avant shuffle
-  Pas de shuffle supplémentaire : Résultats déjà agrégés
-  Sort + take(20) : Appliqué localement
-  WholeStageCodegen (*) : Fusionne les opérations en un seul bytecode JVM

---

##  Concepts clés appris

### Traduction MapReduce → Spark

| Pattern | MapReduce | Spark | Notes |
|---|---|---|---|
| **Combiner** | Agrégation locale avant shuffle | `reduceByKey` (intégré) | Design Pairs en exploite ceci |
| **Groupage** | `groupByKey` | `groupByKey` (pas de combiner) | Design Stripes : shuffle complet |
| **Join** | Basé sur hash | Broadcast (si petit) | Permet le partition pruning |
| **Sort** | Tri-fusion externe | Sort sensible au spill | Exécution de requête adaptative |

### Optimisation de performance

1. **Partitionnement Shuffle**
   - Trop peu : Data skew, dépassement mémoire
   - Trop : Surcharge d'ordonnancement de tâches
   - Optimum : 32 partitions pour 3,6 MB → 1,93 s

2. **Compression Parquet**
   - Snappy : Bon équilibre (47% de réduction dans ce cas)
   - GZIP : Meilleur ratio (50%+) mais plus lent
   - Sans compression : Rapide mais fichiers plus gros

3. **Partition Pruning**
   - Filtres poussés : Réduire les données lues à la source
   - Requête sur boolean_retrieval : 5 fichiers → 1 fichier seulement

---

##  Résumé des résultats

### Top bigrammes (Pairs)
```
1. (i, am):        count=1832, rel_freq=0,0915
2. (my, lord):     count=1645, rel_freq=0,1341
3. (in, the):      count=1605, rel_freq=0,1511
4. (i, have):      count=1580, rel_freq=0,0789
5. (i, will):      count=1528, rel_freq=0,0763
```

### Exemples de paires PMI
```
PMI élevé (co-apparition rare) :
  ('romeo', 'juliet'): PMI ≈ 1,8
  ('fair', 'beautiful'): PMI ≈ 0,7

PMI faible (commun mais indépendant) :
  ('the', 'a'): PMI ≈ 0,02
```

### Statistiques d'index inversé
- **Taille** : 1,9 MB (Parquet, snappy)
- **Original** : 3,6 MB (texte)
- **Compression** : 47% de réduction
- **Latence de requête** : <1 seconde

---

##  Reproductibilité

### Vérification d'environnement

```python
import pyspark
print(f"PySpark: {pyspark.__version__}")      # 4.0.1

import java
print(f"Java: {java.lang.System.getProperty('java.version')}")  # 21.0.6

import sys
print(f"Python: {sys.version}")               # 3.10.19
```

### Exécuter depuis zéro

```bash
# Effacer les sorties et réexécuter
rm -rf outputs proof

# Réexécuter le notebook
jupyter nbconvert --to notebook --inplace --execute BDA_Assignment02.ipynb

# Vérifier les résultats
ls -lh outputs/
cat proof/lab_metrics_log.csv
```

### Contraintes clés de reproductibilité

**Appliquées** :
- Chemins relatifs : `./data/shakespeare.txt` (pas `/mnt/c/...`)
- Seeds fixes (si nécessaire) : `sparkContext.randomSeed = 42`
- Timestamps UTC : Tous les timestamps au format ISO
- Tri déterministe : `ORDER BY + LIMIT`
- Encodage UTF-8 : Tous les I/O texte

---

## Problèmes courants et solutions

### Problème 1 : FileNotFoundException

```python
# ✗ FAUX (chemin absolu)
df = spark.read.text("/mnt/c/Users/phams/Desktop/E5/BigData/Lab2/assignment/data/shakespeare.txt")

# ✓ CORRECT (chemin relatif)
df = spark.read.text("./data/shakespeare.txt")
```

### Problème 2 : Dépassement de mémoire (Stripes)

```python
# Stripes utilise groupByKey → données complètes en mémoire
# Solution : Repartitionner avant groupage
rdd = rdd.repartition(64)  # Plus de partitions → moins de données par tâche
```

### Problème 3 : Shuffle lent

```python
# Vérifier les métriques Spark UI
# Si shuffle_write > input_size × 2, investiguer le skew
# Solution : Utiliser du salt pour les clés de haute cardinalité
df = df.withColumn("salt", F.rand() * 10)
df = df.repartition(32, "key", "salt")
```

### Problème 4 : Métriques manquantes dans lab_metrics_log.csv

```bash
# Ajouter manuellement à partir de Spark UI (http://localhost:4040)
# Pour chaque job : onglet Stages → chercher shuffle_read_mb, shuffle_write_mb
# Ajouter une ligne à proof/lab_metrics_log.csv
```

---

##  Références

### Matériaux du cours
- **Chapitre 3** : Conception d'algorithmes MapReduce (Pairs, Stripes)
- **Chapitre 4** : Analyse de texte (Fréquence, PMI, Indexation)

### Documentation Spark
- [EXPLAIN FORMATTED](https://spark.apache.org/docs/latest/sql-performance-tuning.html)
- [RDD et Streaming](https://spark.apache.org/docs/latest/rdd-programming-guide.html)
- [DataFrame API](https://spark.apache.org/docs/latest/api/python/)

### Outils
- **Spark UI** : `http://localhost:4040` (pendant l'exécution)
- **Jupyter Lab** : `http://localhost:8888`
- **Conda** : Gestion d'environnement isolé

---

### Étapes de téléchargement

```bash
# 1. Ajouter tous les fichiers à Git
cd Lab2/assignment
git add .

# 2. Commit avec message clair
git commit -m "BDA Assignment 02 : Analyse de texte avec Spark (Parties A-D complètes)"

# 3. Push vers GitHub
git push origin main

# 4. Partager le lien du repo dans le formulaire Google
# https://github.com/<votre-nom-utilisateur>/BDA-Labs
```

---

##  Résultats d'apprentissage

Après avoir complété cet assignment, vous devriez comprendre :

1. **Patterns MapReduce** : Compromis Pairs vs Stripes pour l'agrégation
2. **Traduction Spark** : Équivalents RDD/DataFrame/SQL
3. **Analyse de texte** : Fréquence, PMI, indexation inversée
4. **Tuning de performance** : Partitions shuffle, compression, partition pruning
5. **Ingénierie de reproductibilité** : Environnements, chemins relatifs, enregistrement de métriques
6. **Optimisation basée sur preuves** : Plans EXPLAIN, métriques Spark UI

---

