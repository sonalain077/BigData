BDA Assignment02 Overview
Oct 24, 20253 min read

Big Data Analytics — Assignment 02 (Chapter 3 & 4: From MapReduce → Spark + Analyzing Text)
Author : Badr TAJINI - Big Data Analytics - ESIEE 2025-2026

Scope. Implement three text analytics components in PySpark and support them with evidence: (A) Bigram relative frequency with pairs and stripes, (B) PMI with a frequency threshold, (C) Inverted index with boolean retrieval. Add a performance study comparing designs and partition choices.

Learning goals
Translate classic MapReduce text patterns into Spark RDD/DataFrame pipelines.
Compare pairs vs stripes designs for bigram models and PMI. 
Build a simple inverted index and evaluate AND/OR queries.
Read Spark UI metrics and explain formatted physical plans.
Datasets
Shakespeare (~5 MB): data/shakespeare.txt.
Wikipedia Sentences - Collection of 7.8 million sentences from the August 2018 English Wikipedia dump : https://www.kaggle.com/datasets/mikeortman/wikipedia-sentences
Optional: any extra public plain‑text (cite the source) as data/extra.txt.
Tasks
Part A — Bigram relative frequency (pairs and stripes)
Compute relative frequency f(wᵢ, wᵢ₊₁)/f(wᵢ, *). Implement both designs:

Pairs: emit ((wᵢ,wᵢ₊₁),1) and ((wᵢ,*),1), then normalize.
Stripes: emit stripes (wᵢ → {wᵢ₊₁ : count}) and normalize per stripe.
Constraints: lowercase tokenization, split on non‑letters, drop empties. One counting pass then normalization.

Deliverables

outputs/bigram_pairs_top.csv, outputs/bigram_stripes_top.csv (top-N lists by relative freq then count).
proof/plan_bigrams.txt (formatted plan from one DF stage).
Spark UI screenshot for this part.
Part B — PMI with frequency threshold
Compute PMI(x,y) = log10( P(x,y) / (P(x)·P(y)) ) over word pairs that co‑occur within a single line.

Lowercase tokenization; first 40 tokens per line; drop empties.
Keep only pairs with co‑occurrence ≥ K via --threshold K.
Implement with RDDs using either pairs or stripes (you may include both and compare).
Deliverables

outputs/pmi_pairs_sample.csv (or stripes variant), plus proof/plan_pmi.txt if any DF used.
Spark UI screenshot for this part.
Part C — Inverted index + boolean retrieval
Create synthetic documents from Shakespeare by grouping 10 consecutive lines per document (doc_id = floor(line_number/10)). Build an index:

Schema (Parquet): term STRING, df INT, postings ARRAY<STRUCT<doc_id INT, tf INT>>

Implement boolean retrieval AND and OR over postings. Return a list of doc ids with a simple score (e.g., sum of term frequencies). Run at least 3 sample queries.

Deliverables

outputs/index_parquet/ with the schema above.
outputs/queries_and_results.md with the sample queries and top results.
Spark UI screenshot for index build and one query.
Part D — Performance study (short)
Compare pairs vs stripes for Part A (and for PMI if you implemented both). Explain shuffle patterns and object sizes.
Vary spark.sql.shuffle.partitions and report a few metrics: Files Read, Input Size, Shuffle Read/Write.
Include one explain("formatted") for a representative stage and interpret it in 5–8 lines.
Evidence & reproducibility
ENV.md with Python/Java/Spark versions and key Spark configs.
All plans under proof/. All screenshots labeled per part.
Keep paths short; use UTC in sessions; avoid absolute user‑specific paths.
Submission
Executed notebook BDA_Assignment02.ipynb
outputs/, proof/, ENV.md.
genai.md if applicable
Organization
Team. Pair.

Submission. Upload to your Github private repo then share it in the Google Form (Link will be shared soon).

Due Date. 07/12/2025 23:59 paris time.