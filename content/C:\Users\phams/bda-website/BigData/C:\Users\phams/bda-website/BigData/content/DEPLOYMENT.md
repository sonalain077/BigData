# 🚀 Guide de Déploiement du Site Quartz

## 📋 Vue d'ensemble

Ce projet utilise un script automatisé pour déployer les Labs Big Data Analytics sur un site web statique Quartz hébergé sur Cloudflare Pages avec authentification par email.

---

## 🏗️ Architecture

```
BigData (repo GitHub)
├── main                    → Branche de travail (Labs, assignments)
│   ├── Lab0/
│   ├── Lab1/
│   ├── Lab2/
│   │   ├── assignment/
│   │   │   ├── BDA_Assignment02.ipynb
│   │   │   ├── ENV.md
│   │   │   ├── RapportLab2.md
│   │   │   ├── outputs/         → CSV, métriques, résultats
│   │   │   └── proof/           → Plans Spark, screenshots, logs
│   └── Lab3/
│
└── quartz-site             → Branche générée automatiquement (site web)
    └── [Ne jamais modifier manuellement]
```

---

## 🔄 Workflow de Déploiement

### 1️⃣ Tu travailles sur `main` (toujours)

```bash
cd /mnt/c/Users/phams/Desktop/E5/BigData
git checkout main

# Travaille sur tes Labs...
# Modifie Lab2/assignment/RapportLab2.md
# Ajoute des screenshots dans proof/screenshots/
# etc.

git add Lab2/
git commit -m "Lab2 completed"
git push origin main
```

### 2️⃣ Lance le déploiement automatique

```bash
make site/setup
```

**Le script fait automatiquement** :
- ✅ Clone Quartz v4
- ✅ Copie **uniquement** les fichiers pertinents depuis `main`
- ✅ Convertit les notebooks `.ipynb` → HTML
- ✅ Build le site statique
- ✅ Push vers la branche `quartz-site` sur GitHub
- ✅ Déploie sur Cloudflare Pages
- ✅ Configure l'authentification par email

### 3️⃣ Vérifie le site

Accède à : **https://bda-site-son-imad.pages.dev**

---

## 📂 Fichiers Synchronisés

### ✅ Inclus dans le site

| Type | Exemples | Localisation |
|------|----------|--------------|
| **Notebooks** | `*.ipynb` | Convertis en HTML dans `/static/nb/` |
| **Markdown** | `ENV.md`, `RapportLab2.md` | Copiés dans `/content/Lab*/` |
| **Screenshots** | `*.png`, `*.jpg` | `proof/screenshots/` → `/static/` |
| **Plans Spark** | `*.txt` (explain, plan) | `proof/*.txt` → copiés tel quel |
| **Résultats** | `*.csv`, `*.json` | `outputs/` → copiés avec dossiers Spark |
| **Logs** | `lab_metrics_log.csv` | `proof/` → copiés |

### ❌ Exclus du site

- `*Overview.md` (consignes enseignant)
- `*Rubric.md` (grille de notation)
- `data/` (datasets trop gros, sauf `README_DOWNLOAD.md`)
- Fichiers > 25 MiB (limite Cloudflare)

---

## 🔒 Sécurité & Accès

Le site est protégé par **Cloudflare Access** :
- 🎓 Seuls les emails `@esiee.fr` et `@edu.esiee.fr` peuvent accéder
- ⏱️ Session de 30 jours (720h)
- 🔐 Pas de mot de passe : lien de connexion envoyé par email

---

## 🛠️ Structure du Script `setup_quartz_cloudflare.sh`

### Étapes principales

| Étape | Description | Durée |
|-------|-------------|-------|
| **0-3** | Vérification outils (Node.js, gh, wrangler) | 10s |
| **4** | Clone Quartz scaffold | 5s |
| **5** | Nettoyage + sync Markdown (sans Overview/Rubric) | 2s |
| **6** | Conversion notebooks → HTML | 30s |
| **7** | Build index des ressources | 1s |
| **8** | Build site Quartz local | 5s |
| **9** | Git commit + push vers `quartz-site` | 3s |
| **10** | Premier déploiement Cloudflare | 15s |
| **11** | Configuration Access policy | 5s |
| **12** | Rebuild + déploiement final sécurisé | 15s |

**Total** : ~90 secondes

---

## 🎯 Pourquoi 2 Déploiements ?

### Déploiement 1 (Étape 10)
- Upload rapide du site
- Crée le projet Cloudflare si nécessaire

### Déploiement 2 (Étape 12)
- **Applique** la config Access au déploiement final
- Nettoie les gros fichiers (>25 MiB)
- Garantit que la sécurité est active

**Avantage** : Pas de race condition (le site final est toujours protégé).

---

## 🐛 Dépannage

### Problème : Double déploiement sur Cloudflare

**Symptôme** : Tu vois 2 déploiements "Production" par exécution du script.

**Cause** : Cloudflare était configuré pour auto-déployer depuis `main` ET `quartz-site`.

**Solution** : Le script configure maintenant `quartz-site` comme seule branche de production (fixé dans v1.2).

### Problème : Overview.md et Rubric.md apparaissent sur le site

**Symptôme** : Les fichiers de consignes sont publics.

**Cause** : Ancienne version du script ne les filtrait pas.

**Solution** : Le filtre `! -name '*Overview.md' ! -name '*Rubric.md'` est maintenant actif (fixé).

### Problème : Screenshots manquants

**Symptôme** : Les PNG ne s'affichent pas.

**Cause** : Extension en majuscule `.PNG` non détectée.

**Solution** : Le script utilise `-iname` (case-insensitive) pour `.png`, `.jpg`, etc.

### Problème : Fichiers CSV vides

**Symptôme** : Les CSV de `outputs/` sont absents.

**Cause** : Les CSV Spark sont des **dossiers** contenant `part-*.csv`.

**Solution** : Le script copie récursivement tout `outputs/` (dossiers inclus).

---

## 📝 Variables de Configuration

Modifie ces variables dans `setup_quartz_cloudflare.sh` (lignes 5-13) :

```bash
export GH_USER="sonalain077"                      # Ton user GitHub
export REPO="BigData"                             # Nom du repo
export PROJ="bda-site-son-imad"                   # Projet Cloudflare Pages
export EMAIL_DOMAIN="esiee.fr,edu.esiee.fr"       # Domaines autorisés
export CLOUDFLARE_ACCOUNT_ID="62de83..."         # ID compte Cloudflare
export CLOUDFLARE_API_TOKEN="Cxb3dRy0..."        # Token API Cloudflare
```

---

## 🔗 Liens Utiles

- **Site déployé** : https://bda-site-son-imad.pages.dev
- **Repo GitHub** : https://github.com/sonalain077/BigData
- **Dashboard Cloudflare** : https://dash.cloudflare.com → Workers & Pages
- **Quartz docs** : https://quartz.jzhao.xyz

---

## 📌 Commandes Rapides

```bash
# Déployer le site complet
make site/setup

# Vérifier l'état du site local
wsl -d Ubuntu-24.04 bash -c "ls ~/course-website/bda-quartz-site/content/Lab2/assignment/"

# Voir les logs du dernier déploiement
wsl -d Ubuntu-24.04 bash -c "tail -50 /tmp/deploy.log"

# Nettoyer et recommencer
wsl -d Ubuntu-24.04 bash -c "rm -rf ~/course-website/bda-quartz-site"
make site/setup
```

---

## ✅ Checklist Avant Déploiement

- [ ] Tous les Labs commités sur `main`
- [ ] Screenshots dans `proof/screenshots/` (PNG/JPG)
- [ ] Plans Spark dans `proof/*.txt`
- [ ] CSV résultats dans `outputs/`
- [ ] Pas de fichiers > 25 MiB
- [ ] `Overview.md` et `Rubric.md` présents (seront filtrés auto)

---

## 🎓 Pour Ajouter un Nouveau Lab

```bash
# 1. Crée Lab3/ sur main
mkdir -p Lab3/assignment/{outputs,proof/screenshots}

# 2. Ajoute tes fichiers
touch Lab3/assignment/BDA_Assignment03.ipynb
touch Lab3/assignment/RapportLab3.md

# 3. Commit sur main
git add Lab3/
git commit -m "Lab3 added"
git push origin main

# 4. Redéploie
make site/setup
```

Le script synchronise **automatiquement** tous les Labs présents dans le workspace.

---

**Auteur** : Configuration automatisée pour BDA 2025-2026  
**Dernière mise à jour** : 2 décembre 2025
