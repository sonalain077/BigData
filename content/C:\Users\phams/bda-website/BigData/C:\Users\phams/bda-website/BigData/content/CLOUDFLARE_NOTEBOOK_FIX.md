# 🔧 Diagnostic & Solution - Problème d'affichage des notebooks Jupyter sur Cloudflare

**Date**: 2025-01-24  
**Problème**: Les notebooks Jupyter ne s'affichent pas correctement après déploiement sur Cloudflare Pages  
**URL du site**: https://bda-site-son-imad.pages.dev

---

## 🔍 Diagnostic

### Problèmes identifiés

1. **Iframes bloquées** (ligne 325-340 de `setup_quartz_cloudflare.sh`)
   - Les wrappers Markdown utilisaient des `<iframe>` pour intégrer les notebooks HTML
   - Les iframes peuvent être bloquées par Cloudflare Access ou les politiques de sécurité du navigateur
   - Résultat: pages blanches ou notebooks vides

2. **Conversion nbconvert insuffisante** (ligne 285-295)
   - Utilisation de `--no-prompt` et `--no-input` supprime tout le code des notebooks
   - Manque d'options pour embarquer les ressources (CSS, images, JS)
   - Les chemins relatifs vers les assets ne fonctionnent pas sur Cloudflare

3. **Chemins et permaliens cassés**
   - Les URLs encodées peuvent ne pas correspondre aux fichiers réels
   - Les ressources externes (CDN pour CSS/JS) peuvent être bloquées

### Causes racines

```
┌─────────────────────────────────────────────────────────────┐
│ Problème: Notebooks vides après déploiement                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. nbconvert génère HTML avec ressources externes         │
│     ├── CSS/JS chargés depuis CDN (peuvent être bloqués)   │
│     ├── Images en chemins relatifs (cassés sur Cloudflare) │
│     └── Avec --no-input: tout le code disparaît!           │
│                                                             │
│  2. Markdown wrappers utilisent iframes                     │
│     ├── Iframes bloquées par Cloudflare Access            │
│     ├── Sandbox restrictions empêchent JS de s'exécuter    │
│     └── Same-origin policy casse les chemins relatifs      │
│                                                             │
│  3. Quartz static assets plugin                            │
│     ├── Sert /static/nb/*.html correctement                │
│     ├── Mais HTML n'est pas self-contained                 │
│     └── Dépendances externes ne se chargent pas            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ Solutions appliquées

### 1. Conversion nbconvert améliorée

**Avant** (ligne 285-295):
```bash
"$JUPYTER_CMD" nbconvert --to html --output-dir "$outdir" "$nb"
```

**Après**:
```bash
"$JUPYTER_CMD" nbconvert --to html \
  --embed-images \           # Embarque images en base64
  --template=lab \           # Template complet (code + outputs)
  --output-dir "$outdir" \
  "$nb" 2>&1 | tee -a "$SITE_DIR/nbconvert.log"
```

**Bénéfices**:
- ✅ Images embarquées en base64 (pas de chemins cassés)
- ✅ Template 'lab' inclut tout le code et les outputs
- ✅ Logs enregistrés pour debug (nbconvert.log)
- ✅ Fallback vers conversion basique si embed échoue

### 2. Remplacement des iframes par des liens directs

**Avant** (ligne 325-340):
```markdown
📓 **[Open Notebook (Full Screen)](/static/nb/Lab3/assignment/BDA_Assignment03.html)**

---

_Click the link above to view the notebook. Notebooks are best viewed in full screen._
```

**Après**:
```markdown
## View Options

1. **[📓 Open Notebook (Full Screen)](/static/nb/Lab3/assignment/BDA_Assignment03.html)** - Best viewing experience
2. **[⬇️ Download HTML](/static/nb/Lab3/assignment/BDA_Assignment03.html)** - Right-click → Save As

---

### Troubleshooting

If the notebook does not display:
- Check your browser console for errors (F12)
- Try downloading the HTML file and opening it locally
- Clear your browser cache and refresh

**Note**: Notebooks contain embedded CSS/JS. Some browsers may block resources for security.
```

**Bénéfices**:
- ✅ Pas d'iframe = pas de blocage
- ✅ Lien direct vers HTML (navigation simple)
- ✅ Option de téléchargement pour consultation locale
- ✅ Instructions de troubleshooting pour l'utilisateur

### 3. Script de test ajouté

Nouveau fichier: `test_notebook_conversion.sh`

Ce script teste localement:
- ✅ Disponibilité de jupyter/nbconvert
- ✅ Conversion avec différents templates
- ✅ Vérification du contenu HTML (CSS, cells, scripts)
- ✅ Taille des fichiers générés

**Utilisation**:
```bash
bash test_notebook_conversion.sh
```

---

## 🚀 Redéploiement

### Étapes pour appliquer les corrections

1. **Vérifier les modifications**:
   ```bash
   git diff setup_quartz_cloudflare.sh
   ```

2. **Tester localement** (recommandé):
   ```bash
   bash test_notebook_conversion.sh
   ```

3. **Nettoyer et redéployer**:
   ```bash
   # Option 1: Via Makefile (si configuré)
   make site/setup
   
   # Option 2: Script direct
   bash setup_quartz_cloudflare.sh
   ```

4. **Vérifier le déploiement**:
   - Accéder à https://bda-site-son-imad.pages.dev
   - Naviguer vers un lab (ex: Lab3 → assignment → BDA_Assignment03)
   - Cliquer sur "Open Notebook (Full Screen)"
   - **Vérifier**:
     - [ ] Le notebook s'affiche avec le code
     - [ ] Les images/graphiques sont visibles
     - [ ] Les outputs sont présents
     - [ ] Pas de pages blanches ou erreurs 404

5. **Debug en cas de problème**:
   ```bash
   # Vérifier les logs de conversion
   cat ~/bda-website/BigData/nbconvert.log
   
   # Vérifier les fichiers HTML générés
   ls -lh ~/bda-website/BigData/quartz/static/nb/Lab3/assignment/
   
   # Ouvrir un HTML localement pour tester
   firefox ~/bda-website/BigData/quartz/static/nb/Lab3/assignment/BDA_Assignment03.html
   ```

---

## 📊 Métriques attendues

Après le redéploiement, vérifier:

| Métrique | Avant | Après attendu |
|----------|-------|---------------|
| Notebooks affichés correctement | ❌ 0/12 | ✅ 12/12 |
| Taille HTML moyenne | ~50 KB | ~500 KB - 2 MB (avec images embarquées) |
| Temps de chargement | N/A (vide) | < 3s |
| Erreurs console browser | Mixed content, 404 | 0 |

---

## 🔄 Alternatives testées

### ❌ Alternative 1: Utiliser des CDN pour CSS/JS
**Problème**: Bloqués par Cloudflare Access ou CORS

### ❌ Alternative 2: Copier assets séparément
**Problème**: Chemins relatifs cassés, difficile à maintenir

### ✅ Alternative 3: HTML self-contained (solution retenue)
**Avantages**:
- Fonctionne partout (même hors ligne)
- Pas de dépendances externes
- Compatible avec tous les navigateurs
- Facile à télécharger et partager

---

## 📝 Notes complémentaires

### Templates nbconvert disponibles

```bash
# Lister les templates disponibles
jupyter nbconvert --help-all | grep -A 5 "template"

# Templates courants:
# - lab: template complet (code + outputs + interactivité)
# - classic: template simple (legacy)
# - basic: minimal HTML
```

### Options nbconvert utiles

```bash
# HTML self-contained (recommandé pour déploiement)
jupyter nbconvert --to html --embed-images notebook.ipynb

# Cacher le code (outputs seulement)
jupyter nbconvert --to html --no-input notebook.ipynb

# Cacher les prompts (In[1]:, Out[1]:)
jupyter nbconvert --to html --no-prompt notebook.ipynb

# Exécuter le notebook avant conversion
jupyter nbconvert --to html --execute notebook.ipynb
```

### Cloudflare Pages limites

- **Taille max par fichier**: 25 MiB
- **Taille max du build**: 500 MiB
- **Timeout build**: 20 minutes

Si un notebook HTML dépasse 25 MiB:
1. Réduire la résolution des images
2. Supprimer les outputs volumineux
3. Découper en plusieurs notebooks

---

## ✅ Checklist de validation

Avant de considérer le problème résolu:

- [ ] Script `setup_quartz_cloudflare.sh` modifié avec les 3 corrections
- [ ] Script `test_notebook_conversion.sh` exécuté avec succès
- [ ] Site redéployé sur Cloudflare Pages
- [ ] Au moins 3 notebooks testés (Lab1, Lab2, Lab3)
- [ ] Vérification dans 2 navigateurs différents (Chrome, Firefox)
- [ ] Vérification mobile (responsive)
- [ ] Screenshots ajoutés dans `evidence/cloudflare_fix/`
- [ ] Documentation mise à jour dans `DEPLOYMENT.md`

---

## 🎯 Prochaines étapes

Une fois le problème résolu:

1. **Documenter les learnings** dans `DEPLOYMENT.md`
2. **Retourner au Lab4** (Part B: Streaming Analytics)
3. **Appliquer la même solution** pour les futurs labs
4. **Considérer CI/CD** pour déploiement automatique:
   - GitHub Actions pour build/deploy
   - Tests automatiques de conversion
   - Validation des HTML avant push

---

**Responsable**: Assistant GitHub Copilot  
**Dernière mise à jour**: 2025-01-24  
**Status**: ✅ Solutions appliquées, en attente de redéploiement
