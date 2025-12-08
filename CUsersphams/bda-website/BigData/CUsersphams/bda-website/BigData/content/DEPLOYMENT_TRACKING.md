# 📊 Suivi du déploiement Cloudflare - Fix notebooks

**Date**: 2025-01-24 19:10 UTC  
**Commit**: 918f917 - fix(deployment): Cloudflare notebook display with self-contained HTML  
**Script**: setup_quartz_cloudflare.sh  
**Destination**: ~/bda-website/BigData (branche quartz-site)

---

## ⏱️ Timeline du déploiement

| Étape | Status | Durée estimée | Notes |
|-------|--------|---------------|-------|
| 0. Vérification outils | ✅ En cours | <1 min | git, curl, jq |
| 1. Installation Node.js 22 | 🔄 En cours | 2-3 min | Via nvm |
| 2. Installation gh CLI, wrangler | ⏳ En attente | 1-2 min | npm i -g wrangler |
| 3. Authentification GitHub/Cloudflare | ⏳ En attente | <1 min | Déjà configuré |
| 4. Scaffold Quartz | ⏳ En attente | 2-3 min | Clone + npm install |
| 5. Structure du site | ⏳ En attente | <1 min | Création content/ |
| 6. **Conversion notebooks** | ⏳ En attente | **5-8 min** | **CRITIQUE: nbconvert avec --embed-images** |
| 7. Index des labs | ⏳ En attente | <1 min | Génération MD |
| 8. Build Quartz local | ⏳ En attente | 2-3 min | npx quartz build |
| 9. Push vers GitHub | ⏳ En attente | 1-2 min | Branche quartz-site |
| 10. Déploiement Cloudflare | ⏳ En attente | 2-3 min | wrangler pages deploy |
| 11. Configuration Access | ⏳ En attente | 1-2 min | Policies email |
| 12. Build final | ⏳ En attente | 2-3 min | Rebuild + deploy |

**Temps total estimé**: 15-20 minutes

---

## 🎯 Points de vérification critiques

### Étape 6: Conversion notebooks (ligne 285-310)

**AVANT** (problématique):
```bash
jupyter nbconvert --to html --output-dir "$outdir" "$nb"
```

**APRÈS** (corrigé):
```bash
jupyter nbconvert --to html \
  --embed-images \
  --template=lab \
  --output-dir "$outdir" \
  "$nb" 2>&1 | tee -a "$SITE_DIR/nbconvert.log"
```

**À surveiller dans les logs**:
```
[NbConvertApp] Converting notebook Lab3/assignment/BDA_Assignment03.ipynb to html
[NbConvertApp] Writing 1467746 bytes to .../BDA_Assignment03.html
```

**Vérification**:
- Taille HTML ≥ 1 MB (avec images embarquées)
- Pas d'erreurs de conversion
- Log nbconvert.log créé

### Étape 6.2: Création wrappers Markdown

**Nouveau format** (ligne 325-365):
```markdown
## View Options

1. **[📓 Open Notebook (Full Screen)](/static/nb/Lab3/assignment/BDA_Assignment03.html)**
2. **[⬇️ Download HTML](/static/nb/Lab3/assignment/BDA_Assignment03.html)**

### Troubleshooting
...
```

**À vérifier**:
- Pas d'iframes dans les MD générés
- Liens directs vers /static/nb/...html
- Section troubleshooting présente

---

## 📝 Logs attendus

### Succès

```
[19:10:12] 6) Converting notebooks to HTML and wrapping
 - Using jupyter from bda-env: /home/phams/miniconda3/envs/bda-env/bin/jupyter
[NbConvertApp] Converting notebook Lab01/lab1-practice/lab1-practice.ipynb to html
[NbConvertApp] Writing 567234 bytes to .../lab1-practice.html
[NbConvertApp] Converting notebook Lab01/lab1-assignement/BDA_Assignment01.ipynb to html
[NbConvertApp] Writing 834512 bytes to .../BDA_Assignment01.html
[NbConvertApp] Converting notebook Lab2/assignment/BDA_Assignment02.ipynb to html
[NbConvertApp] Writing 1234567 bytes to .../BDA_Assignment02.html
[NbConvertApp] Converting notebook Lab3/assignment/BDA_Assignment03.ipynb to html
[NbConvertApp] Writing 1467746 bytes to .../BDA_Assignment03.html
[NbConvertApp] Converting notebook Lab4/assignment/BDA_Assignment04.ipynb to html
[NbConvertApp] Writing 989123 bytes to .../BDA_Assignment04.html

[19:15:43] 8) Building Quartz site locally
...
[19:17:12] 12) Rebuilding site and publishing final deploy

Deployment done at 2025-01-24 19:18:30  |  Site root: https://bda-site-son-imad.pages.dev
```

### Erreurs possibles

1. **nbconvert échoue**:
   ```
   [NbConvertApp] ERROR: Failed to convert Lab3/assignment/BDA_Assignment03.ipynb
   nbconvert.utils.pandoc.PandocMissing: Pandoc wasn't found
   ```
   → **Action**: Installer pandoc dans bda-env

2. **Template 'lab' non trouvé**:
   ```
   ValueError: No template sub-directory with name 'lab' found
   ```
   → **Action**: Fallback vers template classic (déjà implémenté)

3. **Images trop grosses**:
   ```
   [NbConvertApp] Writing 28567234 bytes (27 MB) to .../notebook.html
   Aborting deploy. Found 1 file(s) >25MiB
   ```
   → **Action**: Réduire résolution images ou split notebook

---

## 🔍 Vérification post-déploiement

Une fois le déploiement terminé:

### 1. Vérifier les logs de conversion

```bash
# Dans WSL/bash
cat ~/bda-website/BigData/nbconvert.log
```

**Vérifier**:
- Toutes les conversions réussies (Lab1-Lab4)
- Taille HTML ≥ 500 KB par notebook
- Pas d'erreurs Pandoc ou templates

### 2. Vérifier le site déployé

**URL**: https://bda-site-son-imad.pages.dev

**Tests manuels**:
1. Accéder à la home page
2. Cliquer sur "Lab3"
3. Cliquer sur "BDA_Assignment03" (📓)
4. Cliquer sur "Open Notebook (Full Screen)"
5. **Vérifier**:
   - [ ] Code Python visible (cellules avec fond gris)
   - [ ] Outputs (DataFrames, métriques) affichés
   - [ ] Images/graphiques présents
   - [ ] Pas de page blanche
   - [ ] Pas d'erreurs console (F12)

### 3. Tester plusieurs notebooks

| Lab | Notebook | Test |
|-----|----------|------|
| Lab1 Practice | lab1-practice | Code + outputs visibles |
| Lab1 Assignment | BDA_Assignment01 | PMI outputs + CSV |
| Lab2 Assignment | BDA_Assignment02 | Index inversé + queries |
| Lab3 Assignment | BDA_Assignment03 | PageRank + PPR + graphs |
| Lab4 Assignment | BDA_Assignment04 | TPC-H queries |

### 4. Vérifier la console navigateur

```javascript
// Pas d'erreurs comme:
// ❌ Failed to load resource: net::ERR_BLOCKED_BY_CLIENT
// ❌ Cross-Origin Request Blocked
// ❌ 404 Not Found: /static/nb/...
```

---

## 📊 Métriques de succès

| Métrique | Avant fix | Après fix (attendu) |
|----------|-----------|---------------------|
| Notebooks affichés | 0/12 (blancs) | 12/12 ✅ |
| Taille HTML moyenne | ~50 KB | ~1-2 MB |
| Temps chargement | N/A | <3s |
| Erreurs console | Mixed content, 404 | 0 |
| Utilisabilité | ❌ Inutilisable | ✅ Lecture complète |

---

## 🚨 Actions en cas d'échec

### Si notebooks toujours blancs:

1. **Vérifier nbconvert.log**:
   ```bash
   cat ~/bda-website/BigData/nbconvert.log
   ```

2. **Télécharger un HTML et ouvrir localement**:
   - Aller sur https://bda-site-son-imad.pages.dev/Lab3/assignment/BDA_Assignment03
   - Cliquer sur "Download HTML"
   - Ouvrir le fichier local dans un navigateur
   - Si ça marche localement → problème Cloudflare
   - Si ça ne marche pas → problème nbconvert

3. **Vérifier la taille des fichiers**:
   ```bash
   ls -lh ~/bda-website/BigData/quartz/static/nb/Lab*/assignment/*.html
   ```
   - Si < 100 KB → images/CSS pas embarquées
   - Si > 25 MB → trop gros pour Cloudflare

4. **Rollback si nécessaire**:
   ```bash
   cd ~/bda-website/BigData
   git reset --hard HEAD~1
   git push -f origin quartz-site
   ```

---

**Dernière mise à jour**: 2025-01-24 19:10 UTC  
**Status**: 🔄 Déploiement en cours...  
**ETA**: 19:25-19:30 UTC
