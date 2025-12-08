#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

CONDA_ENV="${CONDA_ENV:-bda-env}"

PROJECT_ROOT="$(pwd)"

echo "=============================================================="
echo " MODEL TRAINING - Démarrage de l'entrainement du modèle"
echo "=============================================================="
echo ""

FEATURES_PARQUET="data/output/features_parquet"

if [ ! -d "$FEATURES_PARQUET" ]; then
    echo "Dataset Final non trouvé: $FEATURES_PARQUET"
    echo "Lancez d'abord : ./scripts/run_feature_engineering.sh"
    exit 1
fi

echo "Récupération du Dataset en cours..."
echo ""

NOTEBOOK="notebooks/model_training.ipynb"

if [ ! -f "$NOTEBOOK" ]; then
    echo " Le modèle ne peut pas etre entrainé, le notebook introuvable : $NOTEBOOK"
    exit 1
fi

echo "Entrainement du modèle en cours via $NOTEBOOK ..."
echo ""

conda run -n "$CONDA_ENV" jupyter nbconvert \
    --to markdown \
    --execute "$NOTEBOOK" \
    --stdout \
    --no-input \
    --TemplateExporter.exclude_markdown=True \
    2>/dev/null || true

echo ""
echo "Entrainement du modèle terminé !"
echo ""
echo "Modèle sauvegardé : models/best_model_random_forest/"
echo "Métriques loggées : project_metrics_log.csv"
echo ""
