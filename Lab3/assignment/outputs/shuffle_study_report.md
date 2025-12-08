# Shuffle Study Report

## Objective

Analyze SGD reproducibility under random instance order.

## Methodology

- **Dataset**: spam.train.group_y.txt.bz2 (461 instances)
- **Trials**: 1 baseline + 3 shuffled
- **Learning rate**: 0.002
- **Epochs**: 1
- **Seeds**: 42-44

## Results

| Trial | Seed | Accuracy | # Features |
|-------|------|----------|------------|
| Baseline | N/A | 74.5628% | 236,865 |
| Trial 1 | 42 | 71.4754% | 236,865 |
| Trial 2 | 43 | 89.0995% | 236,865 |
| Trial 3 | 44 | 54.4514% | 236,865 |

## Statistical Summary

- **Baseline**: 74.5628%
- **Mean (shuffled)**: 71.6754%
- **Std Dev**: 17.3249%
- **Range**: [54.4514%, 89.0995%]
- **Variance**: 0.030015

## Conclusion

**Assessment**: Unstable - needs tuning

❌ High variance indicates optimization instability.

### Reproducibility Guidelines

1. Always document shuffle seed in ENV.md
2. Use `random.seed()` before shuffle operations
3. Report mean ± std across multiple seeds
4. Consider lower learning rate if variance > 5%

### Note on Sample Size

This study used only 3 trials for faster execution.
For production, recommend 10+ trials for robust statistical analysis.
