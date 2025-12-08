# Big Data Analytics — Labs & Project Roadmap
*ESIEE 2025-2026 – Auteur : Badr TAJINI*

## 1. Objectifs du cours

- Maîtriser les patterns d’analytics distribué pour le texte, les graphes, les données relationnelles et le streaming avec Apache Spark.
- Savoir traduire des questions métiers en pipelines reproductibles, preuves à l’appui (*EXPLAIN FORMATTED*, Spark UI).
- Justifier les choix d’architecture à partir de mesures concrètes (partitions, shuffles, layouts, formats colonne…).
- Relier la théorie (Ch.1–10) à des labs progressifs et aux projets finaux.

## 2. Learning outcomes

- Lire/optimiser un plan physique et interpréter le Spark UI (Files Read, Input Size, Shuffle Read/Write, Spill).
- Choisir des représentations efficaces (e.g. Parquet, partitionnement, compression) et des clés robustes.
- Implémenter PMI, index inversé, PageRank/PPR et requêtes type TPC-H (joins, aggrégats).
- Construire des jobs Structured Streaming (windows, état, sorties idempotentes).
- Livrer ENV.md, plans et "evidence pack" pour garantir la reproductibilité locale.

## 3. Prérequis

- Python et SQL de base.
- Maîtrise du terminal, de Git.
- Introduction à Spark (RDD/DF).
- Bases systèmes/algorithmes appréciées.

## 4. Contenu du cours (10 chapitres)

1. Introduction au Big Data et au coût du stockage.
2. Patterns et exécution MapReduce.
3. Passage MapReduce à Spark (RDD, DF, SQL).
4. Text analytics (fréquences, PMI, index inversé).
5. Graph analytics I (BFS, PageRank).
6. Graph analytics II (Personalized PageRank, base ML).
7. Relational analytics (OLTP/OLAP, SQL-on-Hadoop, Parquet).
8. Real-time analytics (Streaming, structures probabilistes).
9. Mutable state (BigTable/HBase, LSM-trees, compromis CAP).
10. Intégration et synthèse projet.

## 5. Techniques & méthodes

- Mesure systématique : `df.explain("formatted")`, EXPLAIN COST, Spark UI (onglet SQL).
- Patterns : combiners, in-mapper combining, broadcast petites dims, partition pruning.
- Reproductibilité locale : conda, OpenJDK, Spark 4.x, notebooks scriptés, seeds fixés.

## 6. Outils pratiques

- Local-first : conda Python ≥3.10, OpenJDK ≥11, Spark 4.0.x, JupyterLab.
- Relationnel : PostgreSQL via Spark JDBC.
- Streaming : fichiers micro-batch, Kafka en option.

## 7. Évaluation

- Labs (L1–L4, 20%): 5% chacun, evidence requise.
- Assignments/Projets (A01–A04, 60%): 4 vrais cas d’usage.
- Documentation & participation (20%).
- À chaque rendu : ENV.md, plans (formatted), screenshots Spark UI.

## 8. Labs pratiques (couvrant les 10 chapitres)

- **Lab 0:** Bootstrap (install, session, mini DF, UI)
- **Lab 01:** Texte I (Warmup RDD vs DF, WordCount, top‑K, projection)
- **Lab 02:** Texte II (PMI, “first‑40” rule, index inversé)
- **Lab 03:** Graphs I–II (PageRank/PPR, partitions)
- **Lab 04-A:** Relationnel (mini TPC‑H, joins, aggrégation, costs)
- **Lab 04-B:** Streaming (micro‑batch, fenêtre 10/60min, trend state, sinks)
- Livrables spécifiques à chaque lab (topK CSV, plans, UI, logs…).

## 9. Assignments & projets capstone

- **A01:** Texte (RDD/DF, WordCount, fréquences)
- **A02:** Texte avancé (PMI, index inversé, queries)
- **A03:** Graphes (PageRank, PPR, stabilité topK)
- **A04-A:** Relationnel TPC-H (RDD only, joins, Parquet vs TXT)
- **A04-B:** Streaming (pipeline style NYC Taxi, trend detection)
- **A05:** Projet final (expérimentation, rapport, checklist de reproductibilité)


## 10. Références principales

- Syllabus complet (10 chapitres)
- Docs Spark (guide Structured Streaming, EXPLAIN, DataFrame explain("formatted"))

## 11. Livrables attendus (règles générales)

- Notebooks/scripts exécutables
- Screenshots Spark UI par étape clé
- Tables de métriques avant/après chaque optimisation
- Rapports concis et traçables (assumptions, choix, evidence, limites, recommandations)

---

**NB : Pour chaque lab, crée un sous-dossier (ex: Lab01/) et un README.md spécifique (objectifs, datasets, tâches, evidence, conseils) pour clarifier le rendu et faciliter le travail en équipe.**



Actuellement on est dans le lab 4 - assignment

BDA Assignment04 Overview

Oct 24, 20253 min read

Big Data Analytics — Assignment 04 (Chapter 7 & 8 Analyzing Relational Data + Real-Time Analytics (Streaming))
Author : Badr TAJINI - Big Data Analytics - ESIEE 2025-2026

Scope. Single merged assignment for Chapter 7 (Analyzing Relational Data) and Chapter 8 (Real‑Time Analytics).

Two parts:

Part A: Relational (TPC‑H subset) — Implement seven SQL‑style queries using Spark RDDs only. No Spark SQL or DataFrame transforms are allowed, except using DataFrame readers to load Parquet then converting to RDD.
Part B: Streaming (NYC Taxi, one day) — Implement hourly counts, region bounding‑box counts, and a 10‑minute trend detector with state using Structured Streaming file source.
Datasets
Note: (Datasets already shared with you)

Tasks
Part A — TPC‑H bundles (public, tiny scale)
TPC-H‑0.1‑TXT.tar.gz - pipe‑delimited text (one file per table).
TPC-H‑0.1‑PARQUET.tar.gz - Parquet with the same schema. Place extracts under data/tpch/TPC-H-0.1-TXT/ and data/tpch/TPC-H-0.1-PARQUET/.
Part B — Streaming slice
NYC Taxi (one day) - Each part-YYYY-mm-dd-XXXX.csv ≈ one minute of trips. Place under data/taxi-data/.
Environment & Evidence (mandatory)
ENV.md: OS, Python, Java, Spark versions; key Spark configs.
Plans: any DF stage you use → explain("formatted") saved to proof/plan_*.txt.
Spark UI: screenshots with metrics (Files Read, Input Size, Shuffle Read/Write).
Logs: for streaming tasks, keep driver logs and output directories.
Part A — Tasks (RDD‑only, except Parquet loading)
A1 (Q1) — count(*) on lineitem for a given l_shipdate = YYYY‑MM‑DD. Print ANSWER=\d+. A2 (Q2) — First 20 (o_clerk,o_orderkey) where l_orderkey=o_orderkey and l_shipdate=DATE. Reduce‑side join via cogroup. A3 (Q3) — First 20 (l_orderkey,p_name,s_name) for shipped items that day. Broadcast hash join on part, supplier. A4 (Q4) — (n_nationkey,n_name,count) for items shipped to each nation on that day. Mix reduce‑side and broadcast joins. A5 (Q5) — Monthly volumes for US vs CANADA across full warehouse. Emit (nationkey,n_name,YYYY‑MM,count) then plot externally. A6 (Q6) — Modified TPC‑H Q1 “Pricing Summary” filtered on l_shipdate=DATE; compute sums/avgs and emit tuples. Optimize. A7 (Q7) — Modified TPC‑H Q3 “Shipping Priority” top‑10 unshipped orders by revenue before/after dates; optimize joins.

Run both --text and --parquet variants and compare timings.

Part B — Tasks (Structured Streaming)
B1 HourlyTripCount — Windowed counts per hour for the day. B2 RegionEventCount — Hourly counts for two regions using bounding boxes on drop‑off coordinates; keys must be exactly "goldman" and "citigroup". B3 TrendingArrivals — 10‑minute windows. Trigger an alert when current window ≥ 2× previous and current ≥ 10. Persist state per batch and write status files. Print legible alerts to stdout.

CLI contract (examples)
Part A: spark-submit bda_a_relational.py --input data/tpch/TPC-H-0.1-TXT --date 1996-01-01 --text spark-submit bda_a_relational.py --input data/tpch/TPC-H-0.1-PARQUET --date 1996-01-01 --parquet
Part B: spark-submit bda_b_streaming.py --input data/taxi-data --checkpoint ckpt --output out
Hints & Constraints
No Spark SQL or DataFrame transforms in Part A (only allowed to load Parquet then .rdd). Use RDD ops, cogroup joins, broadcast variables for small dimensions.
Convert text rows with split('|'). Define parsers per table.
Validate joins with small samples first. Then measure TXT vs Parquet and explain differences.
For Part B use file source micro‑batches, window durations: 60 min and 10 min. Use state (e.g., mapGroupsWithState or flatMapGroupsWithState) for B3. Persist status files by timestamp.
Submission
Executed notebooks BDA_Assignment04.ipynb.
ENV.md + README.md with exact commands.
Outputs for A1–A7 with required formatting.
proof/ containing plans and Spark UI screenshots.
Streaming logs/ and output/ directories for B1–B3.
genai.md if applicable

Area;	Expectation;	Evidence;
RDD‑only constraint (Part A);	No DF/Spark SQL transforms; only Parquet load then .rdd	code review
Joins;	cogroup for reduce‑side; broadcast for small dims; correct logic	code + perf notes
TXT vs PARQUET;	Both variants run; timings compared; explanation of differences	timings table
Q1–Q7 outputs;	Exact formats (ANSWER=…, tuple lines); top‑10 ordering correctness	outputs/ + checks
Pricing Summary (Q6);	All aggregates correct; efficient pass and combiners	outputs + notes
Streaming hourly;	Correct 1‑hour windows; stable output; checkpointing	logs + UI
Regions & trend;	Bounding‑box filter; correct hourly counts; 10‑min trend with threshold + doubling	outputs + stdout
Plans & UI;	explain("formatted") for DF stages; Spark UI captures	proof/
Reproducibility;	ENV.md, commands, deterministic paths, README	files present

MPORTANT1: Spark UI metrics must be recorded in lab_metrics_log.csv as per the Spark UI guide. Missing or inconsistent metrics will lead to a fail. Capture Spark UI screenshots manually for the evidence.

IMPORTANT2 : lab_metrics_log.csv What is it used for? This file serves as a small logbook for the lab: it records each execution (run_id), the task (topN RDD, topN DF, streaming, etc.), any notes, and some read/traceability metrics (number of files, size read, timestamp). The objective is twofold: to keep a reproducible record of the runs and to have factual support if you are asked “how did you measure this variation?” It is purely a good tracking practice, and you are free to enrich it according to your needs (shuffle, execution time, cluster used, etc.).