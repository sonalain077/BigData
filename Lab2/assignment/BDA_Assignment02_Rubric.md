BDA Assignment02 Rubric
Oct 16, 20252 min read

Big Data Analytics — Assignment 02 Rubric (criteria only)
Author : Badr TAJINI - Big Data Analytics - ESIEE 2025-2026

Area	Expectation	Evidence
Part A — pairs	correct relative frequencies, top list	CSV + plan
Part A — stripes	correct relative frequencies, top list	CSV
Part B — PMI	log10 PMI, first‑40 rule, threshold K	CSV + plan (if DF used)
Part C — index	correct Parquet schema (term, df, postings)	Parquet + sample readback
Part C — queries	AND/OR implemented, reasonable ranking	results md
Part D — performance	partition sweep + trade‑off explanation	UI screenshots + note
Reproducibility	versions + configs documented	ENV.md + notebook
Code quality	clear structure, parameterized paths	notebook
Notes.

Tokenization, first‑40 rule, and log10 base are required where specified.
Keep paths short; avoid user‑specific absolute paths.
IMPORTANT1: Spark UI metrics must be recorded in lab_metrics_log.csv as per the Spark UI guide. Missing or inconsistent metrics will lead to a fail. Capture Spark UI screenshots manually for the evidence.

IMPORTANT2 : lab_metrics_log.csv What is it used for? This file serves as a small logbook for the lab: it records each execution (run_id), the task (topN RDD, topN DF, streaming, etc.), any notes, and some read/traceability metrics (number of files, size read, timestamp). The objective is twofold: to keep a reproducible record of the runs and to have factual support if you are asked “how did you measure this variation?” It is purely a good tracking practice, and you are free to enrich it according to your needs (shuffle, execution time, cluster used, etc.).

