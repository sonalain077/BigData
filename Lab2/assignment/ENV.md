# Environment Configuration — Assignment 02

**Generated**: 2025-11-20T12:00:58Z  
**Location**: `Lab2/assignment/ENV.md`

---

## 1. Operating System

| Property | Value |
|----------|-------|
| **Platform** | Linux-6.6.87.2-microsoft-standard-WSL2-x86_64-with-glibc2.39 |
| **Machine** | x86_64 |
| **Processor** | x86_64 |

---

## 2. Python Environment

| Property | Value |
|----------|-------|
| **Python Version** | 3.10.19 |
| **Python Executable** | /home/phams/miniconda3/envs/bda-env/bin/python3.10 |
| **Environment** | conda (bda-env) |

**Key Packages:**
```
pyspark >= 4.0.0
pandas >= 2.0
numpy >= 1.20
jupyter >= 1.0
regex >= 2023.0
```

Install via:
```bash
conda activate bda-env
pip install pyspark pandas numpy jupyter
```

---

## 3. Java Runtime Environment

```
openjdk version "21.0.6" 2025-01-21
OpenJDK Runtime Environment JBR-21.0.6+9-895.97-nomod (build 21.0.6+9-b895.97)
OpenJDK 64-Bit Server VM JBR-21.0.6+9-895.97-nomod (build 21.0.6+9-b895.97, mixed mode, sharing)
```

**Requirement**: Java 11+ (OpenJDK or Oracle JDK)  
**JAVA_HOME Check**:
```bash
# Windows
echo %JAVA_HOME%

# Linux/macOS
echo $JAVA_HOME
```

---

## 4. Apache Spark

| Property | Value |
|----------|-------|
| **Spark Version** | 4.0.1 |
| **Master** | local[*] |
| **App Name** | ENV_Generator |
| **Spark UI URL** | http://172.19.238.66:4040 |
| **Spark UI Port** | 4040 |

### Key Runtime Configurations

| Config | Value | Purpose |
|--------|-------|---------|
| `spark.sql.shuffle.partitions` | 16 | Partitions for shuffle (optimal: 16–32 for 3.6MB dataset) |
| `spark.sql.adaptive.enabled` | true | Adaptive query execution |
| `spark.sql.adaptive.coalescePartitions.enabled` | Not Set | Coalesce small partitions |
| `spark.sql.parquet.compression.codec` | snappy | Parquet compression (snappy recommended) |
| `spark.driver.memory` | Not Set | Driver JVM heap |
| `spark.executor.memory` | Not Set | Executor JVM heap |
| `spark.executor.cores` | Not Set | CPU cores per executor |
| `spark.default.parallelism` | Not Set | Default RDD parallelism |

---

## 5. Dataset

| Property | Value |
|----------|-------|
| **Source** | `data/shakespeare.txt` |
| **Size** | 3.6 MB (122,458 lines) |
| **Format** | Plain text (UTF-8) |
| **Encoding** | ASCII/UTF-8 |
| **Works** | 37 plays + 154 sonnets |

---

## 6. Assignment 02 Configuration

### Part A — Bigram Relative Frequency

**Optimal Config:**
- `shuffle.partitions`: 32 (measured 1.93s for 286K bigrams)
- Tokenization: lowercase, `[a-z]+` regex
- Approach comparison:
  - **Pairs**: 3.5s (recommandé — early aggregation via reduceByKey)
  - **Stripes**: 84.5s (full groups — slower for this dataset)

**Winner**: Pairs (95.9% faster)

### Part B — PMI with Threshold

**Configuration:**
- First-40 tokens per line (prevents long-tail bias)
- Co-occurrence window: single line
- Min threshold: 10 (configurable via `--threshold K`)
- Log base: 10 (standard PMI)
- Formula: PMI(x,y) = log₁₀( P(x,y) / (P(x) × P(y)) )

### Part C — Inverted Index

**Schema (Parquet):**
```
root
 |-- term: string (nullable = true)
 |-- postings: array (nullable = true)
 |    |-- element: struct (containsNull = true)
 |    |    |-- doc_id: integer (nullable = true)
 |    |    |-- tf: long (nullable = true)
 |-- df: long (nullable = true)
 |-- idf: double (nullable = true)
```

**Document Grouping:**
- 10 consecutive lines = 1 document
- Synthetic doc_id = floor(line_number / 10)
- Total: ~12,000 documents

**Performance:**
- Index size (Parquet): 1.9 MB (47% reduction vs text)
- Build time: 7.6s
- Query optimization: Partition pruning enabled

**Sample Queries:**
1. `love AND heart` → 173 docs
2. `romeo AND juliet` → 16 docs (rare)
3. `fair OR beautiful` → 688 docs

### Part D — Performance Study

**Shuffle Partitions Impact:**

| Configuration | Duration (s) | Bigrams | Notes |
|---------------|--------------|---------|-------|
| 8 partitions | 2.73 | 286,728 | Low parallelism, high data/task |
| 16 partitions | 2.32 | 286,728 | Balanced (Spark default) |
| **32 partitions** | **1.93** | **286,728** | **⭐ Optimal** |
| 64 partitions | 2.31 | 286,728 | Scheduling overhead |

**Recommendation**: `spark.sql.shuffle.partitions = 32` for this dataset

---

## 7. Reproducibility Checklist

### ✅ Local Installation

```bash
# 1. Install Miniconda (if needed)
# Download: https://docs.conda.io/projects/miniconda/en/latest/

# 2. Create isolated environment
conda create -n bda-env python=3.10 -y
conda activate bda-env

# 3. Install PySpark and dependencies
pip install pyspark>=4.0.0 pandas numpy jupyter

# 4. Verify Java
java -version
# Output: OpenJDK 11+ or Oracle JDK 11+

# 5. Start Jupyter
jupyter lab

# 6. (Optional) Set JAVA_HOME if needed
# Windows:
set JAVA_HOME=C:\Program Files\OpenJDK\jdk-11
# Linux/macOS:
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
```

### ✅ Session Setup (all notebooks)

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("BDA_Assignment02") \
    .config("spark.sql.shuffle.partitions", "16") \
    .config("spark.sql.adaptive.enabled", "true") \
    .config("spark.sql.parquet.compression.codec", "snappy") \
    .getOrCreate()

spark.sparkContext.setLogLevel("WARN")
```

### ✅ File Paths (relative)

```python
# ✓ GOOD: Relative paths
SHAKESPEARE_PATH = "./data/shakespeare.txt"
OUTPUT_DIR = "outputs"
PROOF_DIR = "proof"

# ✗ AVOID: Absolute paths
# SHAKESPEARE_PATH = "/mnt/c/Users/phams/Desktop/..."  # Not portable
```

### ✅ Reproducibility Constraints

- **No absolute paths**: Use relative paths (e.g., `./data/`)
- **Fixed seeds** (if needed):
  ```python
  spark.sparkContext.randomSeed = 42
  ```
- **UTF-8 encoding** for all text I/O
- **UTC timestamps** in logs
- **Deterministic order** for top-K results (use `ORDER BY` + `LIMIT`)

---

## 8. Spark UI Access

### During Execution

```
http://localhost:4040
```

### Tabs & Metrics to Monitor

| Tab | Use Case | Key Metrics |
|-----|----------|-------------|
| **Jobs** | Overall job timeline | Duration, stages, shuffle |
| **Stages** | Per-stage breakdown | Input Size, Shuffle R/W, Tasks |
| **SQL/DataFrame** | Physical plans | Partition pruning, broadcasts |
| **Storage** | Cache status | RDD/DF in-memory usage |
| **Executors** | Resource usage | Peak memory, GC time |

### Key Metrics to Log

- **Files Read**: Number of input files accessed
- **Input Size**: Total data read from source (MB)
- **Shuffle Read**: Data shuffled into this partition (MB)
- **Shuffle Write**: Data written during shuffle (MB)
- **Spill**: Memory overflow to disk (should be ≤5% of shuffle)
- **Duration**: Wall-clock time (seconds)

---

## 9. EXPLAIN FORMATTED Interpretation

### Example Output

```
== Physical Plan ==
*(1) Project [word1#123, word2#124, count#125L]
+- *(1) Sort [count#125L DESC NULLS LAST]
   +- Exchange hashpartitioning(word1#123, word2#124, 16)
      +- *(1) HashAggregate(keys=[word1#123, word2#124], functions=[sum(1)])
         +- *(1) HashAggregate(keys=[word1#123, word2#124], functions=[partial_sum(1)])
            +- *(1) Scan text file [path]
```

**How to Read:**
1. **Scan**: Source (RDD, Parquet, text file)
2. **HashAggregate**: Map-side & shuffle-side aggregation (combiner)
3. **Exchange**: Shuffle operation (note the 16 partitions)
4. **Sort**: Final ordering (top-K queries)
5. **Project**: Column selection

**Signs of Efficiency:**
- ✅ Early aggregation (HashAggregate before Exchange)
- ✅ Partition pruning (fewer files read)
- ✅ Broadcast join (no shuffle for small tables)
- ❌ Multiple full table scans (optimize with caching)
- ❌ Cartesian product (missing join condition)

---

## 10. Debugging Common Issues

### Issue: FileNotFoundException

```
ERROR: File not found: /mnt/c/Users/phams/Desktop/.../shakespeare.txt
```

**Solution:**
```python
# Use relative path
SHAKESPEARE_PATH = "./data/shakespeare.txt"

# Verify file exists
import os
assert os.path.exists(SHAKESPEARE_PATH), f"File not found: /mnt/c/Users/phams/Desktop/E5/BigData/Lab2/assignment/data/shakespeare.txt"
```

### Issue: Out of Memory during Stripes

```
java.lang.OutOfMemoryError: Java heap space
```

**Solution:**
```bash
# Increase executor memory
spark-submit --executor-memory 8g script.py

# Or in notebook:
spark.conf.set("spark.executor.memory", "8g")
```

### Issue: Slow Shuffle / Spill to Disk

**Cause**: Too many small partitions or insufficient memory  
**Solution:**
```python
# Reduce partitions
spark.conf.set("spark.sql.shuffle.partitions", "32")

# Or repartition explicitly
df.repartition(32).write.parquet("output")
```

### Issue: Uneven Data Distribution (Task Skew)

**Symptom**: One task runs much slower than others  
**Solution:**
```python
# Salt high-cardinality keys
df = df.withColumn("salt", F.rand())
df = df.repartition(32, "key", "salt")
```

---

## 11. Assignment Deliverables Summary

### Files to Submit

```
Lab2/assignment/
├── BDA_Assignment02.ipynb          ✅ Main notebook (executable)
├── ENV.md                          ✅ This file (reproducibility)
│
├── outputs/
│   ├── bigram_pairs_top_20.csv     ✅ Part A
│   ├── bigram_stripes_top_20.csv   ✅ Part A
│   ├── pmi_filtered.csv            ✅ Part B
│   ├── queries_and_results.md      ✅ Part C
│   ├── performance_pairs_vs_stripes.csv         ✅ Part D
│   ├── performance_shuffle_partitions.csv       ✅ Part D
│   └── performance_analysis.md     ✅ Part D
│
└── proof/
    ├── lab_metrics_log.csv         ✅ Metrics for runs 3–8
    ├── explain_pairs_approach.txt      ✅ Part A
    ├── explain_stripes_approach.txt    ✅ Part A
    ├── explain_pmi_*.txt               ✅ Part B
    ├── explain_retrieval_*.txt         ✅ Part C
    │
    └── screenshots/
        ├── 01_job_103_index_build.png
        ├── 02_query_5_fair_beautiful.png
        └── README.md (screenshot annotations)
```

### Evaluation Criteria

| Criterion | Evidence | Weight |
|-----------|----------|--------|
| **Correctness** | CSV outputs match spec | 40% |
| **Efficiency** | EXPLAIN plans, shuffle metrics | 30% |
| **Reproducibility** | ENV.md, relative paths, seeds | 20% |
| **Documentation** | README, comments, logs | 10% |

---

## 12. References

- **Spark Docs**: https://spark.apache.org/docs/latest/
- **PySpark API**: https://spark.apache.org/docs/latest/api/python/
- **Parquet Format**: https://parquet.apache.org/
- **Course Chapters**: 3–4 (MapReduce Patterns, Text Analytics)

---

## 13. Notes & Recommendations

✅ **Best Practices:**
- Run each section with `spark.sparkContext.setLogLevel("WARN")` to reduce noise
- Save intermediate results to CSV for validation
- Log metrics after each stage (use `lab_metrics_log.csv`)
- Use `df.cache()` for reused DataFrames
- Always call `spark.stop()` at notebook end

❌ **Avoid:**
- Hardcoded absolute paths (use relative paths)
- Very large partitions (>500 MB per partition)
- Unbounded UDFs (can kill performance)
- Cartesian joins without explicit broadcast

✅ **For Performance Tuning:**
- Profile with `df.explain("formatted")` before optimizing
- Measure shuffle metrics from Spark UI (shuffle read/write)
- Test with `shuffle.partitions ∈ [8, 16, 32, 64]`
- Aim for <5% data spill to disk

---

**Last Updated**: 2025-11-20T12:00:58Z  
**Assignment**: BDA Assignment 02 (Chapter 3–4, Text Analytics)  
**Course**: Big Data Analytics — ESIEE 2025-2026  
**Instructor**: Badr TAJINI
