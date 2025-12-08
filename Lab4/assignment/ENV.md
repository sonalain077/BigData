# Lab 4 Assignment - Environment Configuration

**Date:** December 6, 2025  
**Author:** [Votre Nom]  
**Course:** Big Data Analytics - ESIEE 2025-2026

---

## 1. System Information

### Operating System
- **OS:** Windows 11 with WSL2 (Ubuntu 22.04)
- **Architecture:** x86_64

### Hardware
- **CPU:** Intel Core i5 (8 threads)
- **RAM:** 8 GB
- **Storage:** SSD

---

## 2. Software Versions

### Python Environment
- **Python:** 3.10.19
- **Conda Environment:** `bda-env`
- **Conda Version:** [à remplir]

### Apache Spark
- **Spark Version:** 4.0.1
- **Scala Version:** 2.13.15
- **Java Version:** OpenJDK 21.0.6

### Key Libraries
```bash
pyspark==4.0.1
pandas==2.2.3
numpy==2.2.1
jupyter==1.1.1
jupyterlab==4.3.5
matplotlib==3.10.0
```

---

## 3. Spark Configuration

### Local Mode Settings
```python
spark = SparkSession.builder \
    .appName("Lab4-Assignment") \
    .master("local[*]") \
    .config("spark.driver.memory", "4g") \
    .config("spark.executor.memory", "4g") \
    .config("spark.sql.shuffle.partitions", "8") \
    .config("spark.default.parallelism", "8") \
    .getOrCreate()
```

### Key Parameters
- **Driver Memory:** 4GB
- **Executor Memory:** 4GB
- **Shuffle Partitions:** 8 (ajusté selon le dataset)
- **Default Parallelism:** 8

---

## 4. Dataset Information

### Source
- **Dataset:** [À définir selon les consignes du Lab 4]
- **Location:** `Lab4/assignment/data/`
- **Format:** [CSV/Parquet/TXT]
- **Size:** [À mesurer]

---

## 5. Directory Structure

```
Lab4/assignment/
├── BDA_Assignment04.ipynb    # Notebook principal
├── ENV.md                     # Ce fichier
├── RAPPORT.md                 # Rapport final
├── data/                      # Datasets
├── outputs/                   # Résultats (CSV, Parquet, etc.)
├── proof/                     # Plans et preuves
│   ├── plan_*.txt            # Plans d'exécution Spark
│   └── screenshots/          # Captures Spark UI
└── genai.md                   # Déclaration usage IA (si applicable)
```

---

## 6. Reproduction Steps

### Setup Environment
```bash
# Activer l'environnement conda
conda activate bda-env

# Lancer Jupyter Lab
cd /mnt/c/Users/phams/Desktop/E5/BigData/Lab4/assignment
jupyter lab --no-browser --port=8889
```

### Run Notebook
1. Ouvrir `BDA_Assignment04.ipynb`
2. Exécuter toutes les cellules séquentiellement
3. Vérifier les outputs dans `outputs/`
4. Consulter les plans dans `proof/`

---

## 7. Known Issues & Solutions

### Issue 1: [À documenter si problème rencontré]
**Problem:** [Description]  
**Solution:** [Solution appliquée]

---

## 8. Performance Notes

- **Shuffle Partitions:** Optimisé à 8 pour le dataset
- **Broadcast:** [Si utilisé, noter les seuils]
- **Caching:** [Si utilisé, documenter les DataFrames cachés]

---

**Last Updated:** 2025-12-06
