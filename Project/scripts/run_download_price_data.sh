#!/bin/bash
PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
TARGET_DIR="$PROJECT_ROOT/data/prices"
echo "=============================================================="
echo " Démarrage du téléchargement des données Kaggle (Prix du Bitcoin) "
echo "=============================================================="
echo " Destination cible : $TARGET_DIR"
mkdir -p "$TARGET_DIR"

if [ ! -f ~/.kaggle/kaggle.json ]; then
    echo " ERREUR CRITIQUE : Fichier ~/.kaggle/kaggle.json introuvable."
    exit 1
fi

echo " Téléchargement en cours..."

conda run -n bda-env kaggle datasets download \
  -d mczielinski/bitcoin-historical-data \
  -p "$TARGET_DIR" \
  --unzip \
  --force

echo " Terminé ! Liste des fichiers récupérés :"
ls -lh "$TARGET_DIR"