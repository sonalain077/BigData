# Part A - TXT vs Parquet Timings Comparison

## Summary Table

| Task | TXT (s) | Parquet (s) | Speedup | Notes |
|------|---------|-------------|---------|-------|
| A1   | 2.51    | 1.22        | 2.06x   | Parquet columnar scan faster |
| A2   | 18.45   | 9.23        | 2.00x   | Parquet shuffle 50% smaller |
| A3   | 14.79   | 29.46       | 0.50x   | **TXT faster** - investigate |
| A4   | 7.00    | 2.00        | 3.50x   | Parquet optimal for mixed join |
| A5   | 14.39   | 20.98       | 0.69x   | **TXT faster** - small dataset |
| A6   | 7.45    | 11.16       | 0.67x   | **TXT faster** - overhead not amortized |
| A7   | 15.62   | 22.98       | 0.68x   | **TXT faster** - intermediate size |

## Key Observations

1. **Parquet wins** when:
   - Large scans with column pruning (A1, A2, A4)
   - Shuffle-heavy workloads (compression helps)

2. **TXT wins** when:
   - Small filtered datasets (A5, A6, A7)
   - Parquet decompression overhead > benefits
   - Simple arithmetic aggregations (A6)

3. **Anomaly A3**:
   - Expected: Parquet faster (broadcast join)
   - Actual: TXT 2x faster (29.5s vs 14.8s)
   - **Hypothesis**: Small broadcast tables + cold cache = Parquet overhead
   - **Fix**: Warm cache or larger datasets would favor Parquet

## Shuffle Metrics

| Task | TXT Shuffle (MB) | Parquet Shuffle (MB) | Reduction |
|------|------------------|----------------------|-----------|
| A2   | 35.7             | 18.2                 | 49%       |
| A4   | 1.19             | 1.18                 | 1%        |
| A5   | 0.19             | 0.19                 | 0%        |
| A7   | 4.4              | 4.4                  | 0%        |

**Conclusion**: Parquet reduces shuffle significantly only when scan size >> filter selectivity.