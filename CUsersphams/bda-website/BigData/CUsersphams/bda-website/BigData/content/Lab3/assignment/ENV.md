# Environment Configuration — Assignment 03

**Generated**: 2025-12-05T13:54:22Z
**Location**: `Lab3/assignment/ENV.md`

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
| **Python Version** | 3.13.5 |
| **Python Executable** | /home/phams/miniconda3/bin/python3 |
| **Environment** | conda (bda-env) |

**Key Packages:**
```
pyspark >= 4.0.0
pandas >= 2.0
numpy >= 1.20
jupyter >= 1.0
```

**Installation:**
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

---

## 4. Apache Spark

| Property | Value |
|----------|-------|
| **Spark Version** | 4.0.1 |
| **Master** | local[*] |
| **App Name** | BDA_Assignment03 |
| **Spark UI URL** | http://localhost:4040 |

### Key Runtime Configurations

| Config | Value | Purpose |
|--------|-------|---------|\ | `spark.sql.shuffle.partitions` | 16 | Default shuffle partitions |
| `spark.sql.adaptive.enabled` | true | Adaptive query execution |
| `spark.driver.memory` | 4g | Driver JVM heap |
| `spark.executor.memory` | 4g | Executor JVM heap |

---

