#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

CONDA_ENV="${CONDA_ENV:-bda-env}"

PROJECT_ROOT=$(pwd)

echo "=============================================================="
echo " PIPELINE ETL - Démarrage de l'ingestion puis de la transformation des données (prix depuis Kaggle et blocs Bitcoin via Bitcoin Core"
echo "=============================================================="
echo "Project root: $PROJECT_ROOT"
echo ""

PRICE_CSV="$PROJECT_ROOT/data/prices/btcusd_1-min_data.csv"
BLOCKS_DIR="$PROJECT_ROOT/data/blocks/blocks"

if [ ! -f "$PRICE_CSV" ]; then
    echo "Le fichier contenant les prix est introuvable. : $PRICE_CSV"
    echo " Téléchargez d'abord les prix via un script automatique à l'endroit suivant: ./scripts/download_price_data.sh"
    exit 1
fi

if [ ! -d "$BLOCKS_DIR" ]; then
    echo "Le dossier contenant les différents blocs Bitcoin est introuvable.: $BLOCKS_DIR"
    SKIP_BLOCKS=true
else
    BLK_COUNT=$(find "$BLOCKS_DIR" -name "blk*.dat" 2>/dev/null | wc -l)
    if [ "$BLK_COUNT" -eq 0 ]; then
        echo "Aucun fichier blk*.dat trouvé"
        SKIP_BLOCKS=true
    else
        echo "Blocs Bitcoin trouvés:  Il y a au total $BLK_COUNT fichiers blk*.dat."
        SKIP_BLOCKS=false
    fi
fi

echo ""


echo "[1/2] Démarrage de l'ETL des prix du Bitcoin..."
echo "     Input:  $PRICE_CSV"
echo "     Output: data/output/market_parquet/"
echo ""

conda run -n bda-env jupyter nbconvert \
    --to markdown \
    --execute notebooks/etl_market_price.ipynb \
    --stdout \
    --no-input \
    --TemplateExporter.exclude_markdown=True \
    2>/dev/null || true


echo "ETL des prix du Bitcoin terminé !"
echo ""

if [ "$SKIP_BLOCKS" = true ]; then
    echo "[2/2] ⏭️  ETL Blocs ignoré (pas de données)"
else
    echo "[2/2] Démarrage de l'ETL des blocs Bitcoin..."
    echo "     Input:  $BLOCKS_DIR/blk*.dat"
    echo "     Output: data/output/transactions_parquet/"
    echo ""

    conda run -n bda-env jupyter nbconvert \
    --to markdown \
    --execute notebooks/etl_bitcoin_blocks.ipynb \
    --stdout \
    --no-input \
    --TemplateExporter.exclude_markdown=True \
    2>/dev/null || true
 

    echo "ETL des blocs Bitcoin terminé"
fi

echo ""
echo "=============================================================="
echo "ETL TERMINÉ"
echo "=============================================================="
echo ""
echo " Fichiers générés:"
echo "   - data/output/market_parquet/"
[ "$SKIP_BLOCKS" = false ] && echo "   - data/output/transactions_parquet/"
echo ""

