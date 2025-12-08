# Boolean Retrieval Results — Assignment 02, Section 7, Part C

## Objective
Query the inverted index built in Section 6 using AND/OR boolean operators.
Rank results using TF-IDF scoring: Score = Σ(TF × IDF) for all matching terms.

## Index Summary
- Total unique terms: 25,975
- Index format: Parquet (columnar, compressed)
- Query strategy: Partition pruning on 'term' column

## Ranking Strategy
```
Score(doc, query) = Σ ( TF(term, doc) × IDF(term) )
  where:
    TF(term, doc) = frequency of term in document
    IDF(term) = log10( total_docs / df(term) )
```

## Query Results

### Query 1: AND

**Query:** `love AND heart`

**Description:** Documents where love and heart co-occur

**Results:** 173 documents found in 0.350s

#### Top 5 Results

| Rank | Doc ID | TF-IDF Score |
|------|--------|---------------|
| 1 |   6337 |    14.917336 |
| 2 |  11428 |     7.001274 |
| 3 |   8246 |     6.772577 |
| 4 |     79 |     6.099105 |
| 5 |   8153 |     5.870408 |

---

### Query 2: AND

**Query:** `romeo AND juliet`

**Description:** Documents mentioning both main characters

**Results:** 16 documents found in 0.173s

#### Top 5 Results

| Rank | Doc ID | TF-IDF Score |
|------|--------|---------------|
| 1 |   9774 |     8.712889 |
| 2 |   9631 |     8.532433 |
| 3 |   9778 |     6.624895 |
| 4 |   9767 |     6.444439 |
| 5 |   9637 |     4.356445 |

---

### Query 3: AND

**Query:** `king AND queen`

**Description:** Royal context documents

**Results:** 284 documents found in 0.198s

#### Top 5 Results

| Rank | Doc ID | TF-IDF Score |
|------|--------|---------------|
| 1 |   9338 |    10.233188 |
| 2 |   9329 |     9.427590 |
| 3 |   9339 |     8.186551 |
| 4 |   5035 |     6.945512 |
| 5 |   4566 |     6.575353 |

---

### Query 4: OR

**Query:** `love OR hate`

**Description:** Strong emotions (either term)

**Results:** 1623 documents found in 0.124s

#### Top 5 Results

| Rank | Doc ID | TF-IDF Score |
|------|--------|---------------|
| 1 |  11096 |     9.021689 |
| 2 |   9456 |     7.392865 |
| 3 |   1051 |     6.578453 |
| 4 |   1199 |     6.490696 |
| 5 |   8781 |     6.490696 |

---

### Query 5: OR

**Query:** `fair OR beautiful`

**Description:** Aesthetic qualities (either term)

**Results:** 688 documents found in 0.095s

#### Top 5 Results

| Rank | Doc ID | TF-IDF Score |
|------|--------|---------------|
| 1 |  11090 |    12.580476 |
| 2 |   7777 |     6.290238 |
| 3 |  10405 |     5.399969 |
| 4 |   6356 |     5.032190 |
| 5 |   6357 |     5.032190 |

---

## Summary Statistics

| Query | Type | Terms | Results | Time (s) | Top Score |
|-------|------|-------|---------|----------|----------|
| 1 | AND | love, heart |    173 |    0.350 |  14.9173 |
| 2 | AND | romeo, juliet |     16 |    0.173 |   8.7129 |
| 3 | AND | king, queen |    284 |    0.198 |  10.2332 |
| 4 | OR | love, hate |   1623 |    0.124 |   9.0217 |
| 5 | OR | fair, beautiful |    688 |    0.095 |  12.5805 |

## Insights

- **AND queries** return fewer results (stricter filtering)
- **OR queries** return more results (relaxed filtering)
- **TF-IDF scoring** weights rare terms higher (more discriminative)
