#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

CONDA_ENV="${CONDA_ENV:-bda-env}"

PROJECT_ROOT=$(pwd)

echo "=============================================================="
echo " SANITY CHECK de l'ETL"
echo "=============================================================="
echo ""


MARKET_PARQUET="$PROJECT_ROOT/data/output/market_parquet"
TX_PARQUET="$PROJECT_ROOT/data/output/transactions_parquet"

if [ ! -d "$MARKET_PARQUET" ]; then
    echo "Les fichiers parquets contenant les prix sont introuvables. Lancez d'abord: ./scripts/run_etl.sh"
    exit 1
fi

if [ ! -d "$TX_PARQUET" ]; then
    echo "Les fichiers parquets contenant les transactions en bitcoin sont introuvables."
fi

conda run -n bda-env jupyter nbconvert \
    --to markdown \
    --execute notebooks/sanity_check_etl_global.ipynb  \
    --stdout \
    --no-input \
    --TemplateExporter.exclude_markdown=True \
    2>/dev/null || true

echo ""
echo "=============================================================="
echo " SANITY CHECK TERMINÉ"
echo "=============================================================="
echo ""
