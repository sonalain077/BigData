#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
PROJECT_ROOT="$(pwd)"

CONDA_ENV="${CONDA_ENV:-bda-env}"

echo "=============================================================="
echo "BDA Final Project - Bitcoin price movement prediction"
echo "=============================================================="
echo "Racine du projet : $PROJECT_ROOT"
echo "Environnement    : $CONDA_ENV"
echo ""

if ! conda info --envs | grep -q "^${CONDA_ENV} "; then
    echo "Environnement conda '$CONDA_ENV' non trouvé."
    echo "Créez-le avec : conda env create -f conf/bda-env.yml"
    exit 1
fi

echo "[1/6] Téléchargement des données Kaggle..."
if [ -d "data/prices" ] && [ "$(ls -A data/prices 2>/dev/null)" ]; then
    echo "Données Kaggle déjà présentes"
else
    ./scripts/run_download_price_data.sh
fi
echo ""

echo "[2/6] Sanity Check des données brutes  ..."
./scripts/run_sanity_check_price_data.sh
echo ""

echo "[3/6] ETL (CSV/Binaire vers Parquet)..."
./scripts/run_etl.sh
echo ""

echo "[4/6] Sanity Check de l'ETL ..."
./scripts/run_sanity_check_etl.sh
echo ""

echo "[5/6] Jointure et Feature Engineering en cours..."
./scripts/run_feature_engineering.sh
echo ""

echo "[6/6] Entrainement du modèle ..."
./scripts/run_model_training.sh
echo ""

echo "=============================================================="
echo "Pipeline terminé ! Devenez millionaires grace à notre modèle !"
echo "=============================================================="

