# Section 8: Part D — Performance Study Report

## Executive Summary

This section compares **Pairs** vs **Stripes** approaches for bigram frequency counting on Shakespeare data, and analyzes the impact of `spark.sql.shuffle.partitions` configuration.

---

## 1. Pairs vs Stripes Comparison

### Approach Overview

| Aspect | Pairs | Stripes |
|--------|-------|---------|
| **Aggregation Strategy** | `reduceByKey((w1,w2) → count)` | `groupByKey(w1 → [w2:count, ...])` |
| **Shuffle Key** | (word1, word2) | word1 |
| **Early Aggregation** | ✅ Yes (combiner) | ❌ No (full groups) |
| **Memory Profile** | Lower | Higher |
| **Best For** | Fast counting | Statistical analysis |

### Performance Results

```
Approach  Duration (s)  Unique Entries    Shuffle Key                   Strategy             Best For
   Pairs      2.796991          286728 (word1, word2) reduceByKey → pairwise agg        Fast counting
 Stripes     82.109165           21611          word1    groupByKey → stripe agg Statistical analysis
```

### Key Findings

**Winner: Pairs**
- **Duration**: 2.797s (Pairs) vs 82.109s (Stripes)
- **Speedup**: 96.6% faster
- **Unique Bigrams**: 286728 (Pairs) vs 21611 (Stripes unique word1)

**Analysis:**
- Pairs uses `reduceByKey()` with early aggregation → data reduction before network shuffle
- Stripes uses `groupByKey()` → all (word2, count) pairs sent over network, then merged locally
- For Shakespeare data (122458 lines), **Pairs is more efficient** due to reduced shuffle overhead

---

## 2. Shuffle Partitions Impact

### Configuration Variations

```
 shuffle.partitions  Duration (s)  Unique Bigrams
                  8      2.100942          286728
                 16      2.329031          286728
                 32      1.992309          286728
                 64      1.848148          286728
```

### Interpretation

- **shuffle.partitions=8**: Fewer tasks, higher data per task, less coordination overhead
- **shuffle.partitions=16**: Balanced (Spark default), good for medium datasets
- **shuffle.partitions=32**: More parallelism, better for multi-core systems
- **shuffle.partitions=64**: Higher parallelism, but risk of task scheduling overhead

**Recommendation for Shakespeare (3.6 MB):**
- Optimal: `shuffle.partitions = 16–32`
- Rationale: Balances task parallelism with data locality

---

## 3. Execution Plans

### Pairs Approach (EXPLAIN)
**File**: `explain_pairs_approach.txt`

Key stages:
1. **Map**: Extract bigrams from each line
2. **Shuffle**: Group by (word1, word2)
3. **Reduce**: Sum counts (combiner optimizes early)

**Efficiency**: ⭐⭐⭐⭐ (high - early aggregation)

### Stripes Approach (EXPLAIN)
**File**: `explain_stripes_approach.txt`

Key stages:
1. **Map**: Extract stripes (word1 → list of word2)
2. **Shuffle**: Group by word1
3. **Reduce**: Merge stripe dictionaries

**Efficiency**: ⭐⭐⭐ (moderate - full groups before reduce)

---

## 4. Conclusions & Recommendations

### When to Use Pairs
✅ Fast bigram frequency counting  
✅ Limited memory per executor  
✅ High network bandwidth available  
✅ Simple aggregation functions  

### When to Use Stripes
✅ Computing PMI (statistical analysis across contexts)  
✅ Analyzing word co-occurrence patterns  
✅ Building large context dictionaries  
✅ High-memory, low-bandwidth environments  

### Shuffle Configuration Guide
| Dataset Size | shuffle.partitions | Reason |
|--------------|-------------------|--------|
| <100 MB | 8–16 | Minimize overhead, low parallelism needed |
| 100MB–1GB | 16–32 | Balanced approach |
| 1GB–10GB | 32–64 | High parallelism, multi-core |
| >10GB | 64–128 | Distributed across cluster |

---

## 5. Evidence Pack

### Generated Files
- **CSV**: `performance_pairs_vs_stripes.csv`, `performance_shuffle_partitions.csv`
- **Explain Plans**: `explain_pairs_approach.txt`, `explain_stripes_approach.txt`
- **Bigram Outputs**: `bigram_pairs_top_20.csv`, `bigram_stripes_top_20.csv`

### Metrics Logged
- Run ID: 8
- Task: performance_study
- Duration (Pairs + Stripes): 84.906s
- Shuffle Partition Configs: 4

---

**Report Generated**: 2025-11-20T11:24:05.791578  
**Spark Version**: 4.0.1  
**Python Version**: 3.10.19
