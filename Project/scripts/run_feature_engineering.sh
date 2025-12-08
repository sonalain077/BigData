#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

CONDA_ENV="${CONDA_ENV:-bda-env}"

PROJECT_ROOT="$(pwd)"

echo "=============================================================="
echo "FEATURE ENGINEERING - Jointure & Création du Dataset Final"
echo "=============================================================="
echo ""

MARKET_PARQUET="data/output/market_parquet"
TX_PARQUET="data/output/transactions_parquet"

if [ ! -d "$MARKET_PARQUET" ]; then
    echo "Les fichiers parquets contenant les prix sont introuvables : $MARKET_PARQUET"
    echo "Lancez d'abord : ./scripts/run_etl.sh"
    exit 1
fi

if [ ! -d "$TX_PARQUET" ]; then
    echo "Les fichiers parquets contenant les transactions en Bitcoin sont introuvables : $TX_PARQUET"
    echo "Lancez d'abord : ./scripts/run_etl.sh"
    exit 1
fi

echo "Récupération des transactions et des prix en cours ..."
echo ""

NOTEBOOK="notebooks/feature_eng.ipynb"

if [ ! -f "$NOTEBOOK" ]; then
    echo "Notebook non trouvé : $NOTEBOOK"
    exit 1
fi

echo "Exécution de $NOTEBOOK ..."
echo "   (Jointure en cours...)"
echo ""

conda run -n "$CONDA_ENV" jupyter nbconvert \
    --to markdown \
    --execute "$NOTEBOOK" \
    --stdout \
    --no-input \
    --TemplateExporter.exclude_markdown=True \
    2>/dev/null || true

echo ""
echo "Feature Engineering terminé !"
echo "Output : data/output/features_parquet/"
echo ""
