---
title: Home
publish: true
---
# Big Data Analytics — Labs & Projects

**ESIEE 2025-2026** | Auteur : PHAM DANG Son Alain et GAMOUH Imad

##  Contenu

Ce site regroupe les travaux pour le cours Big Data Analytics avec Apache Spark.

###  Labs 

- **Lab 1** - Introduction à Spark & Analyse de Texte
  - Word Count (RDD vs DataFrame)
  - Fréquences de mots
  - PMI (Pointwise Mutual Information)
  - Index inversé

- **Lab 2** - Analyse de Texte Avancée
  - Bigrams (Pairs vs Stripes)
  - PMI optimisé avec "first-40" rule
  - Index inversé Parquet avec requêtes booléennes
  - Étude comparative de performance

- **Lab 3** - Graph Analytics
  - PageRank avec convergence
  - Personalized PageRank (PPR)
  - Analyse de stabilité top-K
  - Optimisation des partitions

- **Lab 4** - Analytics Relationnel & Streaming
  - TPC-H queries (RDD-only, Parquet vs TXT)
  - Structured Streaming avec NYC Taxi data
  - Windowed aggregations
  - Trend detection avec état

###  Projet Final

**Bitcoin Price Prediction with Spark**

Un projet complet de prédiction de la direction du prix du Bitcoin (hausse/baisse) combinant :
- Données on-chain (blockchain Bitcoin - blocs et transactions)
- Données de marché (prix OHLCV via Kaggle)
- Pipeline ETL distribué avec Apache Spark
- Feature engineering (métriques temporelles, ratios, lissages)
- Machine Learning (Random Forest, Gradient Boosting)

Le projet démontre la maîtrise des concepts des 4 labs : manipulation de données texte/binaires, graph analytics (réseau de transactions), analytics relationnel (jointures complexes) et traitement de séries temporelles.

##  Navigation

Explorez les sections dans le menu latéral pour accéder aux notebooks, rapports et résultats détaillés de chaque lab.
