# Lab 4 Assignment - Rapport d'avancement
**Big Data Analytics - ESIEE 2025-2026**  
**Auteur:** PHAM DANG Son Alain et GAMOUH Imad
**Date:** 6 décembre 2025

---

## 1. Introduction

Ce rapport présente l'avancement réalisé sur l'assignment 4 du cours Big Data Analytics, qui couvre deux chapitres majeurs :
- **Chapitre 7 :** Analyse de données relationnelles avec TPC-H
- **Chapitre 8 :** Analyse en temps réel avec streaming

L'objectif est d'implémenter des requêtes complexes sur des données structurées en utilisant uniquement les RDDs Spark (pas de DataFrame transforms en Part A), puis de traiter des flux de données NYC Taxi en streaming (Part B).

---

## 2. Configuration de l'environnement

### 2.1 Versions utilisées
- **Spark:** 4.0.1
- **Python:** 3.10.19
- **PySpark:** 4.0.1
- **Java:** 11.0.25
- **Scala:** 2.13.15
- **Système:** Windows 11 avec WSL2

### 2.2 Configurations Spark
Pour optimiser les performances en environnement local, les paramètres suivants ont été configurés :
```python
spark.sql.session.timeZone = UTC
spark.sql.shuffle.partitions = 8  # Au lieu de 200 par défaut
spark.driver.memory = 4g
spark.executor.memory = 4g
spark.sql.adaptive.enabled = true
```
d
Le choix de 8 partitions pour les shuffles est adapté à une machine locale avec processeur 8 cœurs, réduisant l'overhead de gestion de trop nombreuses partitions.

---

## 3. Part A - Analyse relationnelle TPC-H (RDD-only)

### 3.1 Contexte
L'objectif de cette partie est d'implémenter 7 requêtes SQL-style en utilisant **uniquement des RDDs Spark**, sans utiliser les transformations DataFrame. Seul le chargement des fichiers Parquet est autorisé via DataFrame, converti immédiatement en RDD.

### 3.2 Datasets
Deux formats de données TPC-H sont utilisés :
- **TPC-H-0.1-TXT** : Fichiers texte délimités par '|'
- **TPC-H-0.1-PARQUET** : Fichiers Parquet (format colonne)

Tables principales : `lineitem`, `orders`, `part`, `supplier`, `customer`, `nation`

### 3.3 Requêtes implémentées et résultats

#### A1 - Count simple (Q1)
**Question:** Compter le nombre d'items expédiés à une date précise (1996-01-01)

**Approche:**
- Filtrage RDD sur `l_shipdate`
- Count simple sans shuffle

**Résultats:**
- **Format TXT:** 266 items (13.07s)
- **Format Parquet:** 266 items (9.83s)

**Observations:**
Parquet est environ 25% plus rapide grâce à :
- La lecture sélective des colonnes (projection pushdown)
- La compression efficace
- Le format binaire optimisé

#### A2 - Join reduce-side (Q2)
**Question:** Trouver les 20 premiers `(o_clerk, o_orderkey)` pour les commandes liées aux items expédiés le 1996-01-01

**Approche:**
- Join `lineitem` et `orders` via `cogroup` (reduce-side join)
- Tri par `sortByKey`
- Prise des 20 premiers

**Résultats:**
- **Format TXT:** 20 résultats (16.52s)
- **Format Parquet:** 20 résultats (12.31s)

**Observations:**
Le cogroup génère un shuffle important car il doit regrouper toutes les clés communes. Les métriques Spark UI montrent :
- Shuffle Read: ~1.5 MB
- Shuffle Write: ~1.2 MB
- Parquet plus rapide car lecture initiale plus efficace

#### A3 - Broadcast join (Q3)
**Question:** Trouver les 20 premiers `(l_orderkey, p_name, s_name)` pour les items avec informations produit et fournisseur

**Approche:**
- Broadcast join de `part` et `supplier` (tables petites)
- Map-side join évitant le shuffle
- Collecte locale des dictionnaires

**Résultats:**
- **Format TXT:** 20 résultats (14.89s)
- **Format Parquet:** 20 résultats (11.24s)

**Observations:**
Le broadcast join est très efficace ici car `part` et `supplier` sont petites (<10 MB). Pas de shuffle, toute la jointure se fait localement dans chaque partition.

#### A4 - Join multiple + agrégation (Q4)
**Question:** Compter le nombre d'items par nation expédiés le 1996-01-01

**Approche:**
- Joins multiples: `lineitem` → `orders` → `customer` → `nation`
- Mix de reduce-side join et broadcast
- Agrégation par `n_nationkey`

**Résultats:**
- **Format TXT:** 25 nations (18.73s)
- **Format Parquet:** 25 nations (14.56s)

**Observations:**
Cette requête combine plusieurs patterns :
- Cogroup pour les grandes tables
- Broadcast pour nation (très petite)
- Réduction finale avec `reduceByKey`

#### A5 - Analyse temporelle mensuelle (Q5)
**Question:** Volumes mensuels pour USA vs CANADA sur tout l'entrepôt

**Approche:**
- Filtrage sur `n_name IN ('UNITED STATES', 'CANADA')`
- Extraction de l'année-mois depuis `l_shipdate`
- Groupement par `(nationkey, n_name, year_month)`

**Résultats:**
- **Format TXT:** 24 mois de données (21.45s)
- **Format Parquet:** 24 mois de données (16.89s)

**Observations:**
Cette requête parcourt l'ensemble du dataset sans filtre sur date. Parquet montre ici son avantage majeur : la lecture sélective évite de lire toutes les colonnes.

#### A6 - Pricing Summary (TPC-H Q1 modifié)
**Question:** Calculer des sommes et moyennes de prix/quantités pour les items expédiés le 1996-01-01

**Approche:**
- Map vers tuples de valeurs numériques
- Reduce avec combiners locaux pour optimiser
- Calculs d'agrégats (sum, avg)

**Résultats:**
- **Format TXT:** 8 agrégats calculés (13.92s)
- **Format Parquet:** 8 agrégats calculés (10.67s)

**Observations:**
L'utilisation de `combineByKey` permet de réduire les données localement avant le shuffle, améliorant les performances de 20-30%.

#### A7 - Shipping Priority (TPC-H Q3 modifié)
**Question:** Top 10 commandes non expédiées par revenu

**Approche:**
- Filtrage temporel sur `o_orderdate` et `l_shipdate`
- Join `orders` et `lineitem`
- Calcul du revenu par commande
- Tri décroissant et `take(10)`

**Résultats:**
- **Format TXT:** Top 10 commandes (19.56s)
- **Format Parquet:** Top 10 commandes (15.23s)

**Observations:**
Le tri global avec `sortBy` génère un shuffle important. Le tri sur ~1000 lignes est néanmoins gérable localement.

### 3.4 Comparaison TXT vs Parquet

| Requête | TXT (s) | Parquet (s) | Gain (%) |
|---------|---------|-------------|----------|
| A1      | 13.07   | 9.83        | 24.8%    |
| A2      | 16.52   | 12.31       | 25.5%    |
| A3      | 14.89   | 11.24       | 24.5%    |
| A4      | 18.73   | 14.56       | 22.3%    |
| A5      | 21.45   | 16.89       | 21.3%    |
| A6      | 13.92   | 10.67       | 23.3%    |
| A7      | 19.56   | 15.23       | 22.1%    |
| **Moy.**| **16.88**| **12.96**  | **23.4%**|

**Conclusion:** Parquet offre un gain constant de ~23% grâce à :
1. Lecture colonne par colonne (projection pushdown)
2. Compression efficace (moins d'I/O)
3. Encodage optimisé des types de données
4. Métadonnées permettant de skip des blocs

### 3.5 Patterns RDD observés

**1. In-mapper combining**
Utilisation de `combineByKey` pour agréger localement avant le shuffle :
```python
rdd.combineByKey(
    createCombiner = lambda v: (v, 1),
    mergeValue = lambda acc, v: (acc[0] + v, acc[1] + 1),
    mergeCombiners = lambda a, b: (a[0] + b[0], a[1] + b[1])
)
```

**2. Broadcast join**
Pour les petites dimensions (<100 MB) :
```python
part_dict = part_rdd.collectAsMap()
bc_part = sc.broadcast(part_dict)
lineitem_rdd.map(lambda x: (x, bc_part.value.get(x.partkey)))
```

**3. Reduce-side join**
Via `cogroup` pour les grandes tables :
```python
lineitem_rdd.map(lambda x: (x.orderkey, x)) \
    .cogroup(orders_rdd.map(lambda x: (x.orderkey, x)))
```

---

## 4. Part B - Streaming Analytics (NYC Taxi)

### 4.1 Contexte
L'objectif est de traiter des flux de données NYC Yellow Cab 2015 en mode streaming, avec des fenêtres temporelles et détection de tendances.

### 4.2 Dataset
**NYC Yellow Cab - 1er décembre 2015**
- 1440 fichiers CSV (1 par minute)
- 20 colonnes par enregistrement
- Champs clés : `pickup_datetime`, `dropoff_datetime`, `pickup_longitude`, `pickup_latitude`, `dropoff_longitude`, `dropoff_latitude`

**Problème rencontré:** Le dataset a 20 colonnes au lieu des 14 initialement attendues. Le schéma a dû être corrigé.

### 4.3 Tâche B1 - Hourly Trip Count

**Question:** Compter le nombre de trajets par fenêtre d'une heure

**Approche:**
1. Lecture en streaming des CSV avec schéma fixe (20 colonnes)
2. Parsing de `pickup_datetime` (position 1)
3. Fenêtrage d'1 heure avec `window()`
4. Agrégation par fenêtre
5. Écriture en mode append vers Parquet

**Code clé:**
```python
df_stream = spark.readStream.schema(taxi_schema).csv(taxi_path)
df_windowed = df_stream \
    .withColumn("pickup_ts", to_timestamp("pickup_datetime")) \
    .withWatermark("pickup_ts", "10 minutes") \
    .groupBy(window("pickup_ts", "1 hour")) \
    .count()
```

**Résultat actuel:**
- **Status:** Implémenté mais 0 résultat
- **Durée d'exécution:** 59.22s
- **Windows:** 0
- **Trips:** 0

**Diagnostic:**
Le problème vient du parsing de `pickup_datetime`. La colonne est lue comme string mais le format exact n'est pas reconnu par `to_timestamp()`. Solutions à tester :
1. Utiliser `to_timestamp()` avec format explicite : `yyyy-MM-dd HH:mm:ss`
2. Vérifier que la colonne 1 contient bien des timestamps valides
3. Examiner les logs Spark pour voir les erreurs de parsing

### 4.4 Tâches B2 et B3 - Non commencées

**B2 - RegionEventCount (goldman, citigroup)**
- Filtrage géographique par bounding boxes
- Comptage horaire par région
- Non implémenté

**B3 - TrendingArrivals**
- Fenêtres de 10 minutes
- Détection de doublage de volume
- État persistant entre batches
- Non implémenté

---

## 5. Evidence et Reproductibilité

### 5.1 Fichiers générés

**Part A - Outputs:**
- `outputs/a1_result_txt_19960101.txt` (266 items)
- `outputs/a1_result_parquet_19960101.txt` (266 items)
- `outputs/a2_result_txt_19960101.txt` (20 résultats)
- `outputs/a2_result_parquet_19960101.txt` (20 résultats)
- ... (tous les A1-A7)

**Part A - Plans:**
- `proof/plan_a2_lineitem_parquet_19960101.txt`
- `proof/plan_a2_orders_parquet_19960101.txt`
- ... (plans pour chaque requête)

**Part A - Spark UI Screenshots:**
- `proof/screenshots/a2_alljobs.PNG`
- `proof/screenshots/a2_cogroup.PNG`
- `proof/screenshots/a3_broadcast_parquet.PNG`
- ... (captures d'écran pour A2-A7)

**Part B - Output:**
- `output/b1_hourly/*.parquet` (résultats streaming)
- `outputs/b1_hourly_trip_count.txt` (résumé)
- `proof/plan_b1_hourly_stream.txt` (plan d'exécution)

### 5.2 Métriques trackées

Un fichier `proof/lab_metrics_log.csv` contient :
- run_id
- task (A1-A7, B1-B3)
- format (TXT/Parquet/Streaming)
- date
- num_files
- input_size_mb
- duration_s
- shuffle_read_mb
- shuffle_write_mb
- notes
- timestamp

Cela permet de comparer les performances entre les exécutions et les formats.

---

## 6. Difficultés rencontrées et solutions

### 6.1 Parsing RDD depuis texte
**Problème:** Les fichiers TXT sont délimités par '|' et certaines colonnes peuvent être vides.

**Solution:**
```python
def parse_lineitem_txt(line):
    fields = line.split('|')
    return Lineitem(
        l_orderkey=int(fields[0]) if fields[0] else 0,
        l_shipdate=fields[10] if len(fields) > 10 else None,
        # ...
    )
```

Utilisation de valeurs par défaut et vérification de longueur.

### 6.2 Gestion des shuffles
**Problème:** Les cogroup génèrent de gros shuffles (>100 MB) sur les grandes tables.

**Solution:**
- Broadcast des petites tables (<10 MB)
- Réduction de `spark.sql.shuffle.partitions` à 8
- Utilisation de combiners locaux

### 6.3 Schéma NYC Taxi
**Problème:** Dataset avec 20 colonnes au lieu de 14, causant des erreurs de parsing.

**Solution:**
Redéfinition complète du schéma avec les 20 colonnes :
```python
taxi_schema = StructType([
    StructField("VendorID", StringType(), True),
    StructField("pickup_datetime", StringType(), True),  # Position 1
    StructField("dropoff_datetime", StringType(), True),
    # ... 17 autres colonnes
])
```

### 6.4 Parsing timestamp en streaming
**Problème:** `to_timestamp()` retourne NULL pour tous les enregistrements.

**Solution en cours:**
- Tester avec format explicite
- Examiner les 10 premières lignes du CSV
- Vérifier les logs Spark pour erreurs de conversion

---

## 7. Leçons apprises

### 7.1 RDD vs DataFrame
L'utilisation pure RDD force à comprendre :
- Les mécanismes de shuffle
- Les patterns de jointure (map-side vs reduce-side)
- L'importance des combiners locaux
- La gestion manuelle des types

Cela donne une meilleure compréhension de ce que Spark Catalyst fait automatiquement avec les DataFrames.

### 7.2 Parquet vs Texte
Parquet n'est pas juste "un format de stockage" mais apporte :
- 23% de gain en performance moyenne
- Réduction de l'I/O réseau/disque
- Meilleure compression (ratio ~3:1)
- Préservation des types de données

Pour des datasets >1 GB, Parquet devient indispensable.

### 7.3 Streaming nécessite validation
Le mode streaming n'affiche pas d'erreurs claires quand :
- Le schéma est incorrect
- Le parsing échoue silencieusement
- Les timestamps sont invalides

Il faut systématiquement vérifier :
1. Les logs Spark
2. Les métriques du query
3. Les premiers résultats intermédiaires

---

## 8. Prochaines étapes

### 8.1 Correction B1
1. Débugger le parsing de `pickup_datetime`
2. Tester avec `to_timestamp(col, 'yyyy-MM-dd HH:mm:ss')`
3. Valider sur un échantillon de 10 fichiers
4. Relancer sur les 1440 fichiers

### 8.2 Implémentation B2
1. Définir les bounding boxes goldman et citigroup
2. Filtrer sur `dropoff_longitude` et `dropoff_latitude`
3. Ajouter une colonne `region` avec `when().otherwise()`
4. Fenêtrage 1 heure + groupBy region
5. Écriture en append

### 8.3 Implémentation B3
1. Fenêtrage 10 minutes
2. Utilisation de `mapGroupsWithState` pour comparer fenêtre actuelle vs précédente
3. Détection condition : `current_count >= 2 * previous_count AND current_count >= 10`
4. Persistance de fichiers status par batch
5. Affichage des alertes sur stdout

### 8.4 Documentation finale
1. Compléter README.md avec commandes spark-submit exactes
2. Mettre à jour ENV.md avec toutes les dépendances
3. Vérifier que tous les plans sont sauvegardés
4. Organiser les screenshots par tâche
5. Finaliser le checklist de reproductibilité

---

## 9. Conclusion

Le Lab 4 Assignment représente une étape importante dans l'apprentissage de Spark :

**Part A (Relationnelle) :** Complétée à 100%
- 7 requêtes TPC-H implémentées en RDD pur
- Comparaison TXT vs Parquet réalisée
- Evidence complète (plans, screenshots, outputs)
- Gain de 23% avec Parquet démontré

**Part B (Streaming) :** Partiellement complétée (33%)
- B1 implémenté mais nécessite débugging
- B2 et B3 à implémenter
- Architecture streaming en place

**Compétences acquises :**
- Manipulation bas niveau des RDDs
- Patterns de jointure optimisés
- Compréhension des shuffles
- Streaming avec fenêtres temporelles
- Mesure de performance systématique

**Points d'amélioration :**
- Validation plus précoce des schémas de données
- Tests sur échantillons avant traitement complet
- Meilleure gestion des logs pour diagnostic

Le travail restant est principalement le débugging de B1 et l'implémentation de B2-B3, ce qui représente environ 3-4 heures de travail supplémentaire.
