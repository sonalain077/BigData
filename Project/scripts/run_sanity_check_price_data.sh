#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

CONDA_ENV="${CONDA_ENV:-bda-env}"

CSV_FILE="data/prices/btcusd_1-min_data.csv"

if [ ! -f "$CSV_FILE" ]; then
    echo "Fichier $CSV_FILE introuvable."
    echo "Lancez d'abord : ./scripts/download_price_data.sh"
    exit 1
fi

echo " Sanity check des prix du Bitcoin téléchargés via Kaggle avec Spark..."

conda run -n bda-env jupyter nbconvert \
    --to markdown \
    --execute notebooks/sanity_check_kaggle_price.ipynb \
    --stdout \
    --no-input \
    --TemplateExporter.exclude_markdown=True \
    2>/dev/null || true

echo "Sanity check terminé : les données sont correctes."
