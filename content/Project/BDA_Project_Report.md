# Bitcoin Price Prediction with Spark

**Auteurs :** Imad GAMOUH - Son PHAM DANG  
**Cours :** Big Data 

## 1. Problem & Objectives

### 1.1 Explication du problème 

Le marché du Bitcoin est caractérisé par une forte volatilité et une opacité qui rend la prédiction des mouvements de prix particulièrement difficile. Ce projet vise à prédire la direction du prix du Bitcoin (hausse ou baisse), en exploitant des données on-chain (activité de la blockchain) combinées aux données de marché (prix OHLCV).

**Contexte technique :**  
- Les données on-chain (transactions, blocs) sont volumineuses (~1 Go de fichiers binaires bruts) et nécessitent un traitement distribué.
- La granularité des données est hétérogène : prix à la minute, nouveau blocs environ toutes les 10 minutes.
- Le pipeline complet (ingestion, ETL, feature engineering puis Machine Learning) doit être reproductible et scalable.

**Enjeux Big Data :**
- Parser des fichiers binaires Bitcoin (`blk*.dat`) de manière parallélisée.
- Joindre deux sources de données à granularités différentes via Spark.
- Construire des features temporelles robustes.

### 1.2 Target (Cible)

La variable cible est **binaire** :
- `label = 1` : le prix de clôture à l'heure suivante (t+1) est supérieur au prix actuel, c'est à dire qu'on observe une hausse
- `label = 0` : le prix de clôture à l'heure suivante est inférieur ou égal, on observe une baisse

### 1.3 Horizon temporel

- **Horizon de prédiction :** 1 heure
- **Granularité des features :** horaire (agrégation des données minute et des transactions)
- **Période couverte par les prix réupérés via Kaggle :** 01/01/2012 à Maintenant 
- **Période couverte par les blocs Bitcoins :** du mois de décembre 2013 à janvier 2014 (mode pruning utilisé lors du téléchargement via Bitcoin Core)

### 1.4 Hypothèses principales

Ce projet repose sur quatre hypothèses fondamentales qui guident nos choix d'architecture et de modélisation :

- **H1 : Le pouvoir prédictif des métriques On-Chain**

Les mouvements de fonds sur la blockchain (registre public) précèdent souvent les mouvements de prix sur les marchés (les échanges). Nous supposons que les gros portefeuilles **Whales** et les mineurs sont plus informés : un afflux soudain de transactions de gros montants (détecté par notre seuil dynamique P99) signalerait une potentielle intention d'achat  ou de vente avant que cela ne se reflète dans le prix.

- **H2 : La pertinence du lissage du bruit**

L'agrégation horaire est le compromis optimal entre la réactivité du signal et la stabilité des données. En effet, les blocs Bitcoin arrivent de manière irrégulière (environ toutes les 10 mins en moyenne) : travailler à la minute créerait trop de valeurs bruitées. Ainsi, lisser sur une heure permettrait de dégager des tendances plus exploitables par un modèle de Machine Learning.

- **H3 : La nécessité de la stationnarité**

Un modèle entraîné sur des valeurs financières brutes (Prix en $, Volume en BTC) ne peut pas généraliser sur une longue période. Le Bitcoin est une série temporelle non-stationnaire (sa moyenne et sa variance changent au cours du temps). Un modèle apprenant que "Si Volume > 1000 BTC" en 2012 (où c'était courant) échouera en 2024 (où c'est très rare, la valeur du BTC à changer entre-temps).

Nous devons transformer les données en invariants d'échelle (Rendements %, Z-Scores, Ratios) pour capturer la dynamique du marché plutôt que les niveaux absolus.

- **H4 : L'intégrité temporelle**

L'évaluation de la performance n'est valide que si elle respecte strictement la flèche du temps.En effet, dans un contexte de trading, et en série temporelles plus en  général, nous ne connaissons jamais le futur. Un partitionnement aléatoire (par exemple via un randomSplit) introduirait un Data Leakage massif (le modèle apprendrait des données de demain pour prédire aujourd'hui). Seul un Split Temporel Strict (Train = Passé et Test = Futur) permettrait d'estimer la performance réelle en production.

## 2. Data

Cette section détaille les deux types de sources de données hétérogènes utilisées dans ce projet, allant de fichiers CSV structurés aux fichiers binaires bruts issus du protocole Bitcoin.

### 2.1 Sources de données

#### Description des données

#### A. Données de Marché (Prix - Structuré)

- **Source** : Kaggle (`Bitcoin Historical Data`)
- **Format** : Fichier CSV unique (`btcusd_1-min_data.csv`)
- **Granularité** : 1 minute (haute fréquence)
- **Contenu** : Données **OHLCV** (*Open, High, Low, Close, Volume*) 
- **Volume** : ~4,8 millions de lignes (~366 Mo)
- **Intérêt** : Sert de **"Target** pour l'entraînement supervisé  
  > Question prédictive : *« le prix monte-t-il ou descend-il ? »*


#### B. Données Blockchain (Réseau - Non-structuré/Binaire)

- **Source** : Nœud Bitcoin Core local 
- **Format** : Fichiers binaires propriétaires (`blkXXXXX.dat`)
- **Structure** : Chaque fichier contient une suite de blocs sérialisés selon le protocole Bitcoin :
  - Magic bytes
  - Header
  - Transaction 
- **Volume brut** : Environ **1,4 Go** (mode *Pruning*)
- **Intérêt** : Fournit les métriques fondamentales du réseau :
  - Activité des mineurs
  - Volume de transactions
  - Comportement des whales 

### 2.2 Licences et conditions d'usage

| Dataset | Licence | URL |
|---------|---------|-----|
| `mczielinski/bitcoin-historical-data` | CC-BY-SA-4.0 | (https://www.kaggle.com/datasets/mczielinski/bitcoin-historical-data) |
| Blocs Bitcoin Core | Bitcoin Core | (https://bitcoincore.org) |

### 2.3 Méthode de collecte (fetch)

L'acquisition respecte les contraintes de **reproductibilité** et d’**automatisation** du projet.

---
Nous utilisons l’API **Kaggle** via un script Shell encapsulé :  
`run_download_price_data.sh`

Ce script prend en charge :

- l’authentification (via le token `kaggle.json`)
- le téléchargement des données
- la décompression automatique dans le répertoire : `data/prices/`

---

Pour respecter la contrainte de stockage (environ 1 Go) sans télécharger la blockchain complète, nous avons configuré Bitcoin Core en mode pruning.

- **Configuration** :  
  `prune=2048` dans `bitcoin.conf` (limite à 2 Go).

- **Processus** :  
  Le noeud télécharge la blockchain mais ne conserve sur disque que les blocs les plus récents.

- **Arrêt** :  
  La synchronisation a été interrompue manuellement une fois le volume cible atteint (environ 1,4 Go), capturant ainsi une fenêtre continue de blocs.

- **Défi technique** :  
  Les fichiers `blkXXXXX.dat` sont des fichiers binaires non lisibles directement par un humain.

Le parsing des fichiers binaires est effectué en parallèle via Spark RDD, permettant de scaler horizontalement si nécessaire.

### 2.4 Fenêtre de couverture

| Dataset | Date début | Date fin | Volume |
|---------|------------|----------|--------|
| **Prix (Kaggle)** | 01/01/2012 | 31/03/2021 | environ 4,857,377 lignes |
| **Blocs (Bitcoin Core)** | 05/12/2013 | 15/01/2014 |environ 5700 blocs |

> **Note :** La plage de chevauchement entre les deux sources est d'environ **1 mois** (décembre 2013 à janvier 2014). C'est sur cette intersection que le modèle est entraîné et évalué.

---

## 3. Pipeline

### 3.1 Vue d'ensemble du flux

Voici une vue d'ensemble du flux, permettant de mieux décomposer et comprendre le problème :

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Ingestion  │ →  │     ETL      │ →  │    Joins     │ →  │   Features   │ →  │    Model     │
│  (raw data)  │    │ (Parquet)    │    │  (hourly)    │    │   (Gold)     │    │  (Training)  │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
```

### 3.2 Étapes détaillées

#### 3.2.1 Ingestion

| Étape | Script | Notebook | Description |
|-------|--------|----------|-------------|
| Téléchargement prix | `scripts/run_download_price_data.sh` | - | Récupère le CSV Kaggle |
| Validation prix | `scripts/run_sanity_check_price_data.sh` | `notebooks/sanity_check_kaggle_price.ipynb` | Vérifie le schéma et les données brutes |

#### 3.2.2 ETL (Extract-Transform-Load)

| Étape | Script | Notebook | Input | Output |
|-------|--------|----------|-------|--------|
| ETL Prix | `scripts/run_etl.sh` | `notebooks/etl_market_price.ipynb` | `data/prices/btcusd_1-min_data.csv` | `data/output/market_parquet/` |
| ETL Blocs | `scripts/run_etl.sh` | `notebooks/etl_bitcoin_blocks.ipynb` | `data/blocks/blocks/blk*.dat` | `data/output/transactions_parquet/` |
| Sanity Check ETL | `scripts/run_sanity_check_etl.sh` | `notebooks/sanity_check_etl_global.ipynb` | Parquets générés | Validation schémas et overlap |


- ETL prix :
Le CSV brut est typé en `string` par défaut : on effectue un casting explicite en `double/long`.
On crée des colonnes dérivées (`timestamp_hour`, `datetime`, `date`, `hour`) pour permettre la jointure, le partitionnement ainsi que de créer de la diversité dans les features.
On écrit les fichiers récupérés en **Parquet** : permet la compression des données, une lecture colonnaire ainsi qu'un schéma intégré.

- ETL prix :
Les fichiers `blk*.dat` sont des binaires d'envrion 130 Mo chacun. On réalise un parsing **sérialisable** sur les workers Spark puis une distribution via `spark.sparkContext.parallelize(file_paths)` et `flatMap(parse_blk_file)`.
Ainsi, chaque worker traite un fichier indépendamment, ce qui permet une **scalabilité horizontale**.

#### 3.2.3 Jointure et Feature Engineering

| Étape | Script | Notebook | Description |
|-------|--------|----------|-------------|
| Feature Engineering | `scripts/run_feature_engineering.sh` | `notebooks/feature_eng.ipynb` | Jointure + création de 18 features |

**Processus :**
1. **Agrégation on-chain horaire** : `groupBy("timestamp_hour")` sur les transactions → `tx_count`, `volume_btc`, `whale_tx_count`, etc.
2. **Agrégation market horaire** : `groupBy("timestamp_hour")` sur les prix minute → OHLCV horaire + `volatility`.
3. **Inner Join** sur `timestamp_hour` → seules les heures avec données des deux sources sont conservées.
4. **Window Functions** : lags (`lag(close, 1)`), rendements (`return_1h`, `return_24h`), moyennes mobiles (`close_ma24`), z-scores (`tx_count_zscore`).
5. **Label** : `lead("close", 1) > close ? 1 : 0`.

De plus, on crée certaines variables comme un seuil whale par exemple, qui est calculé dynamiquement via `approxQuantile(0.99)`, qui est adaptatif à la période : en effet, à l'époque le BTC était beaucoup moins cher ce qui le rendait beaucoup plus accessible et faussait la notion de whale. On définit des features stationnaires comme les z-scores qui normalisent l'activité par rapport aux 24h précédentes.
On encode de manière cyclique via le sinus et cosinus les dates et heures car elles pourraient fausser le modèle qui pourrait croire qu'il existe une notion d'ordre : par exemple, 23h>1h.

#### 3.2.4 Entraînement du modèle

| Étape | Script | Notebook | Description |
|-------|--------|----------|-------------|
| Model Training | `scripts/run_model_training.sh` | `notebooks/model_training.ipynb` | RF + GBT + Ablation Study |

### 3.3 Schémas des datasets clés

#### Schéma des Parquets Transactions (11 colonnes)

| Colonne | Type | Description |
|---------|------|-------------|
| `tx_id` | string | Identifiant unique de la transaction |
| `block_hash` | string | Hash du bloc contenant la transaction |
| `timestamp` | long | Timestamp Unix du bloc |
| `n_inputs` | int | Nombre d'entrées |
| `n_outputs` | int | Nombre de sorties |
| `amount_sats` | long | Montant total transféré en satoshis |
| `block_size` | int | Taille du bloc en octets |
| `datetime` | timestamp | Timestamp formaté |
| `timestamp_hour` | long | Clé de jointure (arrondi à l'heure) |
| `date` | date | Date extraite |
| `hour` | int | Heure extraite |

#### Schéma des Parquets Prix du Marché  (10 colonnes)

| Colonne | Type | Description |
|---------|------|-------------|
| `Timestamp` | double | Timestamp Unix original |
| `Open` | double | Prix d'ouverture |
| `High` | double | Prix le plus haut |
| `Low` | double | Prix le plus bas |
| `Close` | double | Prix de clôture |
| `Volume` | double | Volume échangé |
| `datetime` | timestamp | Timestamp formaté |
| `timestamp_hour` | long | Clé de jointure |
| `date` | date | Date extraite |
| `hour` | int | Heure extraite |

#### Features Parquet (20 colonnes)

On crée ainsi le dataset final avec les features suivantes, dont on peut retrouver les features ci-dessous :

| Colonne | Type | Catégorie |
|---------|------|-----------|
| `timestamp_hour` | long | Identifiant |
| `close` | double | Prix |
| `return_1h`, `return_24h` | double | Momentum |
| `volatility_24h` | double | Risque |
| `volume_exchange` | double | Market |
| `tx_count`, `volume_btc` | long/double | On-chain |
| `whale_tx_count`, `whale_volume_btc` | long/double | Whales |
| `miner_issuance_btc` | double | Émission |
| `nvt_like`, `onchain_vs_exchange` | double | Ratios |
| `tx_count_zscore`, `whale_zscore`, `issuance_zscore` | double | Anomalies |
| `hour_of_day`, `day_of_week` | int | Calendrier |
| `label` | int | Cible (0/1) |

### 3.4 Tailles d'échantillon

On obtient à la fin un Parquet contenant nos features, avec environ 933 valeurs.

### 3.5 Orchestration de la pipeline

Le script principal `run_all.sh` à la racine orchestre l'ensemble :

```bash
./run_all.sh
```

**Séquence d'exécution :**
1. `[1/6]` `scripts/run_download_price_data.sh` → Téléchargement Kaggle
2. `[2/6]` `scripts/run_sanity_check_price_data.sh` → Validation données brutes
3. `[3/6]` `scripts/run_etl.sh` → ETL CSV + binaires → Parquet
4. `[4/6]` `scripts/run_sanity_check_etl.sh` → Validation ETL
5. `[5/6]` `scripts/run_feature_engineering.sh` → Jointure + Features
6. `[6/6]` `scripts/run_model_training.sh` → Entraînement ML

---

## 4. Protocole Expérimental et Modélisation

Cette section détaille la méthodologie rigoureuse mise en place pour entraîner, évaluer et comparer nos modèles prédictifs, en tenant compte des spécificités des séries temporelles financières et des contraintes de généralisation.

---

### 4.1 Stratégie de Partitionnement (Train/Test Split)

Contrairement aux problèmes de classification classiques où les observations sont indépendantes, la prédiction financière repose sur des **données séquentielles**. L'ordre chronologique est donc une information structurelle cruciale.

#### Notre approche : Le Split Temporel Strict

Nous avons divisé le dataset, préalablement trié par `timestamp_hour`, en deux sous-ensembles disjoints :

- **Ensemble d'entraînement (Train – 80%)**  
  Correspond aux **748 premières heures** de notre jeu de données commun (décembre 2013).  
  → C'est sur cette période passée que le modèle apprend les corrélations historiques.

- **Ensemble de test (Test – 20%)**  
  Correspond aux **185 dernières heures** (janvier 2014).  
  → Cet ensemble est strictement futur par rapport à l'entraînement et n'est utilisé que pour l'évaluation finale, simulant une mise en production réelle.

---

### 4.2 Définition de la Baseline 

Avant d'interpréter les résultats d'un algorithme complexe, il est indispensable de définir un **point de comparaison naïf**.

Nous avons analysé la distribution de la variable cible (`label`) dans notre jeu d'entraînement :

- Le marché est **haussier** (*Label = 1*) dans **52,43%** des cas.  
- Le marché est **baissier** (*Label = 0*) dans **47,57%** des cas.

#### Baseline Naïve

Un modèle simpliste qui prédirait systématiquement la **classe majoritaire** (*"Hausse"*) obtiendrait mécaniquement une précision (**Accuracy**) de :

> **0,5243**

#### Critère de succès

Pour qu'un modèle de Machine Learning soit considéré comme apportant de la valeur (*Signal vs Bruit*), il doit démontrer une **Accuracy significativement supérieure** à cette baseline sur le jeu de test.

---

### 4.3 Choix des Algorithmes : Bagging vs Boosting

Pour notre tâche de **classification binaire** sur des données financières **bruitées**, nous avons sélectionné deux approches d’**Ensemble Learning** complémentaires :

#### A. Random Forest (L'approche Stable)

Nous utilisons le **Random Forest** comme modèle principal pour sa capacité à réduire la Variance.
Naturellement résistant à l'**overfitting**, un problème majeur sur les marchés volatils comme le Bitcoin. Cependant, il nécessite un fin réglages des hyperparamètres pour fournir une performance robuste.


#### B. Gradient Boosted Trees (L'approche axée performance)

Nous utilisons le **Gradient Boosted Trees (GBT)** comme challenge* pour sa capacité à réduire le Biais. En effet, il est considéré comme état de l'art pour les données tabulaires et est capable de capter des **relations non-linéaires fines**. Il est en revanche plus sensible au bruit, avec un risque d'overfitting' des outliers s'il n'est pas finement réglé.

### 4.4 Étude d'Ablation (Ablation Study)

Un défi majeur de la modélisation financière est la **non-stationnarité** : le prix du Bitcoin a varié de plusieurs dizaine de milliers dollars depuis 2012.
Un modèle apprenant des seuils de prix absolus deviendrait obsolète très vite.

Pour tester la robustesse de notre **Feature Engineering**, nous avons mené une étude comparative :

#### Modèle Brut (18 features)

- Inclut **toutes les variables**, y compris les **prix bruts** (`close`, `open`, `volume_btc`).  
- **Risque** :  
  - Performance potentiellement élevée à court terme.  
  - Mais risque de mémorisation des niveaux de prix spécifiques à 2013.

#### Modèle plus robuste (14 features)

- Exclut toutes les valeurs absolues.  
- Ne contient que des features **stationnaires** :
  - Rendements en % (`return_1h`)
  - Z-Scores (`tx_count_zscore`)
  - Ratios (`nvt`, `onchain_vs_exchange`)
  - Signaux cycliques (`sin/cos hour`)

### 4.5 Traçabilité et MLOps

Dans une démarche d’industrialisation, chaque exécution du pipeline est historisée automatiquement pour garantir la reproductibilité des expériences.

Nous avons implémenté un système de Logging MLOps léger** :

- Toutes les métriques (accuracy, auc, f1-score) et les paramètres sont enregistrés dans le fichier :  
  `project_metrics_log.csv`

- Chaque exécution possède un Run ID unique (ex : `model_train_20251207_173423`).

- Les artefacts sont sauvegardés dans le dossier :  
  `models/`

Cette infrastructure permet de comparer objectivement l’évolution des performances au fil des itérations.

## 5. Analyse de Performance et Preuves d'Exécution

Cette section fournit les preuves tangibles de la bonne exécution distribuée du pipeline, en s'appuyant sur les métriques de modélisation*et l'analyse des plans d'exécution Spark.

---

### 5.1 Métriques d'Évaluation du Modèle

Pour évaluer la pertinence de nos modèles de classification binaire, nous nous appuyons sur trois métriques complémentaires :

| Métrique | Rôle dans le projet                                                                                               | Formule                                            |
|---------|--------------------------------------------------------------------------------------------------------------------|----------------------------------------------------|
| Accuracy | Indicateur global de succès. Permet la **comparaison directe avec la Baseline**.                                 | $\frac{TP + TN}{Total}$                            |
| F1-Score | Métrique d'équilibre. Cruciale si les classes (Hausse/Baisse) sont déséquilibrées, car elle pénalise les modèles qui ne prédisent qu'une seule classe. | $2 \times \frac{Precision \times Recall}{Precision + Recall}$ |
| AUC-ROC  | Capacité de discrimination. Mesure la probabilité que le modèle classe un exemple positif aléatoire plus haut qu'un exemple négatif. C'est la métrique la plus robuste aux **seuils de décision**. | Aire sous la courbe ROC                            |

---

### 5.2 Analyse des Plans d'Exécution (`explain`)

Les plans physiques générés par Spark (`explain("formatted")`) sont archivés dans le dossier `evidence/` et démontrent l'efficacité des optimisations Catalyst.

#### A. Ingestion et ETL (`block_ingestion_explain.txt`)

Le plan montre une exécution linéaire (*Narrow Transformation*) :

- Opérations:  
  `Scan ExistingRDD → Project → InMemoryTableScan`

- Observation :  
  Aucune étape d'Exchange n'est présente.  
  → Cela confirme que le parsing des blocs binaires est parfaitement parallélisable et s'exécute localement sur chaque worker sans nécessiter de communication réseau (pas de Shuffle).

---

#### B. Feature Engineering (`feature_engineering_explain.txt`)

C'est l'étape la plus complexe, impliquant des **agrégations** et des **jointures**.

- BroadcastHashJoin:  
  Le plan révèle l'utilisation d'un `BroadcastExchange` pour la jointure.  
  Spark a détecté que la table agrégée des transactions (~958 lignes) est suffisamment petite pour être diffusée à tous les noeuds, évitant ainsi un coûteux `SortMergeJoin` qui aurait nécessité de déplacer les millions de lignes de la table des prix.

- **Window Functions** :  
  Les calculs de fenêtre (Lags, Z-Scores) déclenchent des opérateurs `Window` précédés de `Sort`.  
  → Bien que coûteux, ces tris sont indispensables pour respecter l'ordre chronologique des séries temporelles.

De plus, les filtres temporels (ex : `isnotnull(timestamp_hour)`) sont poussés au plus près de la source de données (Scan Parquet) afin de minimiser le volume de données lu en mémoire.

---

#### C. Entraînement (`model_training_explain.txt`)

Le plan confirme l'efficacité du **format Parquet** :

L'opérateur `Scan parquet` lit uniquement les colonnes nécessaires*aux features, ignorant les métadonnées ou colonnes inutiles.

Le filtre de split train/test (`timestamp_hour < split_ts`) est appliqué dès la lecture, réduisant le volume de données propagé dans le DAG.

---

### 5.3 Analyse de la Spark UI (Monitoring)

Les captures d'écran de l'interface Spark (dossier `evidence/`) valident le comportement du cluster lors de l'exécution.

| Phase          | Observation clé                                                                                                                                          | Preuve                         |
|----------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------|
| ETL Blocs      | **Zéro Shuffle.** Le job s'exécute en une seule *Stage*, confirmant l'absence de transfert de données entre nœuds lors du parsing.                       | `proof_no_shuffle.jpg`         |
| Feature Eng.   | **Shuffle maîtrisé.** On observe un volume de *Shuffle Read* d'environ **149,7 KiB** pour l'agrégation finale. C'est un volume extrêmement faible comparé à la taille des données, ce qui prouve l'efficacité de l'agrégation avant jointure. | `dag_job_shuffle.jpg`          |
| Parallélisme   | **Utilisation des ressources.** Les tâches (*Tasks*) sont bien réparties (**12/12 complétées**), indiquant une bonne distribution de la charge sans *Data Skew* majeur. | `ingestion_market_price.jpg`   |

---


L'architecture du pipeline minimise les goulots d'étranglement I/O et Réseau en privilégiant les transformations locales, exploite efficacement les stratégies de jointure optimisées de Spark et démontre, via les plans d'exécution et la Spark UI, une exécution distribuée maîtrisée et adaptée aux contraintes de volumétrie du projet.

---

## 6. Résultats et Discussion

Cette section présente les performances des modèles entraînés, analyse l'importance des variables prédictives et discute les limites techniques et éthiques de notre approche.

---

### 6.1 Performance des Modèles

#### Tableau comparatif des résultats

| Modèle           | Features  | Accuracy | F1-Score | AUC-ROC | Δ vs Baseline |
|------------------|-----------|----------|----------|---------|---------------|
| Baseline Naïve   | -         | 0.5243   | -        | 0.5000  | -             |
| Random Forest    | ALL (18)  | 0.5730   | 0.5730   | 0.6105  | +4.87 %       |
| GBT              | ALL (18)  | 0.5459   | 0.5458   | 0.5975  | +2.16 %       |

#### Analyse

- Le Random Forest s'impose comme le modèle le plus performant avec une Accuracy de 57,30 % et une AUC de 0,61.  
- Il bat significativement la baseline (**+4,87 %**), ce qui confirme qu'il existe un léger signal prédictif exploitable dans nos données combinées (Prix + Blockchain).  
- Le GBT, bien que supérieur à la baseline, sous-performe légèrement le Random Forest, confirmant sa sensibilité au bruit et la nécessité d'un réglage d'hyperparamètres plus poussé.

---

### 6.2 Analyse de l'Importance des Features (Top 10)

Pour comprendre pourquoi le modèle prend ses décisions, nous avons extrait l'importance des variables (*Feature Importance*) du Random Forest.

#### Top 10 des variables les plus discriminantes

| Rang | Feature              | Importance | Interprétation économique                                                                                             |
|------|----------------------|-----------:|------------------------------------------------------------------------------------------------------------------------|
| 1    | `return_1h`          | 0.0962     | Momentum court terme : la tendance de l'heure précédente est le meilleur prédicteur de l'heure suivante.              |
| 2    | `tx_count_zscore`    | 0.0875     | Signal d'anomalie : activité réseau anormalement élevée (Z-Score) liée aux mouvements de prix, souvent via les whales.|
| 3    | `volume_btc`         | 0.0869     | Intérêt réel : volume déplacé on-chain comme proxy de la "vérité" économique.                                         |
| 4    | `volume_exchange`    | 0.0852     | Activité de trading spéculative sur les plateformes.                                                                  |
| 5    | `hour_of_day`        | 0.0840     | Saisonnalité : influence des heures d'ouverture des marchés (US, Asie) sur la volatilité.                             |
| 6    | `tx_count`           | 0.0796     | Activité brute du réseau.                                                                                             |
| 7    | `return_24h`         | 0.0774     | Momentum moyen terme.                                                                                                 |
| 8    | `nvt_like`           | 0.0763     | Ratio de valorisation (Prix / Volume on-chain).                                                                       |
| 9    | `avg_block_size`     | 0.0757     | Proxy de la congestion du réseau.                                                                                     |
| 10   | `onchain_vs_exchange`| 0.0723     | Ratio flux réels vs flux spéculatifs.                                                                                 |

 
Ainsi, le modèle s'appuie sur un mélange équilibré de signaux techniques (Prix, Momentum) et de signaux fondamentaux (Activité On-Chain, Whales).

---

### 6.3 Étude d'Ablation (Ablation Study)

Afin de tester la robustesse de notre modélisation face à l'évolution des prix (**non-stationnarité**), nous avons comparé le modèle complet à un modèle restreint aux variables stationnaires.

#### Résultats de l'ablation

| Jeu de features       | Accuracy | AUC-ROC | Observation                                                |
|-----------------------|----------|---------|------------------------------------------------------------|
| ALL (18 features)     | 0.5730   | 0.6105  | Utilise les prix bruts (`close`, `open`).                  |
| GENERALISABLE (14)    | 0.5405   | 0.5907  | Sans prix bruts. Perte de ~3 % d'accuracy.                |

#### Interprétation

- Le modèle **"Généralisable"** (sans les prix bruts) conserve une performance très honorable (**54 %**), supérieure à la baseline.  
- Cependant, la baisse de performance (**-3,25 %**) indique que le modèle **"Brut"** s'appuie encore en partie sur des **niveaux de prix absolus**.  
- Le modèle restreint est théoriquement plus robuste pour le futur, car il base ses décisions uniquement sur la dynamique du marché (rendements, ratios) et non sur sa valeur.

---

### 6.4 Limites et Perspectives

Malgré des résultats encourageants, ce travail exploratoire présente plusieurs limitations aux contraintes du projet.

#### A. Faible chevauchement temporel

- Notre fenêtre d'analyse commune (Prix + Blockchain) ne couvre qu'environ **40 jours**.  
- Il ya donc un fort risque d'overfitting sur cette période spécifique du marché.  

#### B. Mode Pruning

- L'utilisation du mode **"Pruning"** nous limite aux blocs les plus récents au moment de la synchronisation.  


#### C. Absence de Tuning

- Les hyperparamètres des modèles (Random Forest, GBT) ont été fixés  aléatoirement, alors qu'en réalité, ils nécessitent un travail d'affinement.  


---

## 7. Reproducibility

### 7.1 Procédure pas-à-pas

#### Étape 1 : Cloner le dépôt

```bash
git clone https://github.com/sonalain077/BigData
cd Project
```

#### Étape 2 : Lire les prérequis (`ENV.md`)

**Prérequis :**
- **Python** : 3.10.19
- **Java (OpenJDK)** : 21.0.6
- **PySpark** : 4.0.1
- **Conda** : requis pour la gestion de l'environnement
- **API Kaggle** : token configuré dans `~/.kaggle/kaggle.json`

Le fichier `ENV.md` à la racine du projet documente les versions exactes des dépendances.

**Installation de l'environnement Conda :**
```bash
conda env create -f conf/bda_env.yml
conda activate bda-env
```
**Paramètre à ajuster selon votre environnement :**
- `spark.driver_memory` : augmenter si vous avez plus de RAM (ex: `8g`)


#### Étape 4 : Lancer le pipeline complet

```bash
# Sur WSL
chmod +x run_all.sh
chmod +x scripts/*.sh
./run_all.sh

# Sur Windows PowerShell 
wsl bash "./run_all.sh"
```

Le script exécute les 6 étapes dans l'ordre :
1. Téléchargement des prix Kaggle
2. Sanity check des données brutes
3. ETL (CSV + binaires → Parquet)
4. Sanity check de l'ETL
5. Feature engineering (jointure + création features)
6. Entraînement du modèle (RF + GBT)

#### Étape 5 : Exécuter un notebook individuellement

```bash
# Téléchargement des données prix
./scripts/run_download_price_data.sh

# Sanity check des prix bruts
./scripts/run_sanity_check_price_data.sh

# ETL (prix + blocs)
./scripts/run_etl.sh

# Sanity check de l'ETL
./scripts/run_sanity_check_etl.sh

# Feature engineering
./scripts/run_feature_engineering.sh

# Entraînement du modèle
./scripts/run_model_training.sh
```


#### Logs d'expériences (`project_metrics_log.csv`)

Le fichier est généré/mis à jour automatiquement lors de l'exécution de notebooks comme `notebooks/model_training.ipynb`. Pour le recréer :
```bash
# Supprimer l'ancien fichier
rm project_metrics_log.csv



#### Preuves Spark UI (`evidence/Spark UI/`)

Les captures de la Spark UI sont stockées dans `evidence/Spark UI/` :


### 7.3 Arborescence complète du projet

```
new_project/
├── conf/
│   ├── bda_env.yml                          # Environnement Conda
│   ├── bda_project_config.yml               # Configuration Spark et chemins
│   └── .ipynb_checkpoints/
├── data/
│   ├── blocks/
│   │   ├── blocks/                          # Fichiers blk*.dat (blocs Bitcoin bruts)
│   │   │   ├── blk00099.dat
│   │   │   ├── blk00100.dat
│   │   │   ├── ... (autres blocs)
│   │   │   └── index/                       # Index LevelDB
│   │   └── btc_blocks_pruned_1GiB.tar.gz   # Archive originale
│   ├── prices/
│   │   ├── btcusd_1-min_data.csv            # Prix minute (Kaggle)
│   │   ├── btc_1h_data_2018_to_2025.csv
│   │   ├── btc_4h_data_2018_to_2025.csv
│   │   ├── btc_1d_data_2018_to_2025.csv
│   │   ├── btc_15m_data_2018_to_2025.csv
│   │   └── .ipynb_checkpoints/
│   └── output/
│       ├── transactions_parquet/            # (généré par etl_bitcoin_blocks.ipynb)
│       │   ├── part-00000-*.snappy.parquet
│       │   ├── part-00001-*.snappy.parquet
│       │   └── ... (9 partitions)
│       ├── market_parquet/                  # (généré par etl_market_price.ipynb)
│       │   ├── part-00000-*.snappy.parquet
│       │   ├── part-00001-*.snappy.parquet
│       │   └── ... (12 partitions)
│       └── features_parquet/                # (généré par feature_eng.ipynb)
│           └── part-00000-*.snappy.parquet
├── evidence/
│   ├── block_ingestion_explain.txt          # Plan Spark ETL blocs
│   ├── market_etl_explain.txt               # Plan Spark ETL prix
│   ├── feature_engineering_explain.txt      # Plan Spark feature eng.
│   ├── model_training_explain.txt           # Plan Spark model training
│   ├── model_training_summary.txt           # Résumé des résultats
│   ├── Data Acquisition (Part A and Part B)/
│   │   ├── Part A/                          # Preuve Bitcoin Core installation
│   │   │   ├── A1_version_bitcoin_core.png
│   │   │   ├── A2_config_pruning.png
│   │   │   ├── A3_node_sync_logs_proof.txt
│   │   │   ├── A4_final_stop_size.png
│   │   │   └── bitcoin.conf
│   │   └── Part B/                          # Preuve Kaggle download
│   │       ├── Kaggle_Authentification.jpg
│   │       └── Automated_Ingestion.jpg
│   └── Spark UI/
│       ├── etl_bitcoin_blocks/
│       │   ├── job_list.jpg
│       │   └── proof_no_shuffle.jpg
│       ├── etl_market_price/
│       │   └── ingestion_market_price.jpg
│       ├── feature_engineering/
│       │   ├── job_list_1.jpg
│       │   ├── job_list_2.jpg
│       │   ├── job_list_3.jpg
│       │   ├── dag_job_shuffle.jpg
│       │   └── proof_shuffle.jpg
│       └── model_training/
│           ├── aggreg_stat_nodes_rf.jpg
│           └── model_training_iterative.jpg
├── models/
│   └── best_model_random_forest/            # (généré par model_training.ipynb)
│       ├── metadata/
│       └── stages/
│           ├── 0_VectorAssembler_*/
│           ├── 1_StandardScaler_*/
│           └── 2_RandomForestClassifier_*/
├── notebooks/
│   ├── etl_bitcoin_blocks.ipynb             # ETL : parsing blocs binaires
│   ├── etl_market_price.ipynb               # ETL : transformation CSV → Parquet
│   ├── sanity_check_kaggle_price.ipynb      # Validation données brutes
│   ├── sanity_check_etl_global.ipynb        # Validation ETL globale
│   ├── feature_eng.ipynb                    # Jointure + création 18 features
│   ├── model_training.ipynb                 # RF + GBT + Ablation Study
│   ├── generate_env.ipynb                   # Génération ENV.md
│   └── .ipynb_checkpoints/
├── scripts/
│   ├── run_download_price_data.sh           # Lance sanity_check_kaggle_price.ipynb
│   ├── run_sanity_check_price_data.sh       # Lance sanity_check_kaggle_price.ipynb
│   ├── run_etl.sh                           # Lance etl_market_price.ipynb + etl_bitcoin_blocks.ipynb
│   ├── run_sanity_check_etl.sh              # Lance sanity_check_etl_global.ipynb
│   ├── run_feature_engineering.sh           # Lance feature_eng.ipynb
│   ├── run_model_training.sh                # Lance model_training.ipynb
│   └── .ipynb_checkpoints/
├── ENV.md                                   # Prérequis (versions Python, Spark, packages)
├── project_metrics_log.csv                  # Logs des expériences (auto-généré)
├── lab_metrics_log.csv                      # Ancien fichier de metrics
├── run_all.sh                               # Script orchestrateur principal
├── BDA_Project_Report.md                    # Rapport technique détaillé
├── READMEv2.md                              # Ce fichier (README complet)
├── report.md                                # Rapport synthétique
└── .ipynb_checkpoints/
```

**Fin du README**
