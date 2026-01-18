#!/usr/bin/env bash
set -e

LOCKFILE="/tmp/chandra_ocr.lock"
exec 9>"$LOCKFILE" || exit 1
flock -n 9 || exit 0

# -------- defaults --------
INPUT=""
BASE_OUT=""
START=1
END=0
STEP=10
BATCH_SIZE=5
PROJECT_DIR="/home/bhickta/development/chandra"
VENV="$PROJECT_DIR/.venv/bin/activate"

# -------- usage --------
# -------- usage --------
usage() {
    echo "Usage:"
    echo "  ocr_chunks.sh -i <input.pdf> -o <output_base|output_dir> -e <end_page> [options]"
    echo
    echo "Required:"
    echo "  -i   Input PDF"
    echo "  -o   Output base OR output directory"
    echo "  -e   End page"
    echo
    echo "Optional:"
    echo "  -m   Inference method (default: vllm)"
    echo "  -s   Start page (default: auto-resume or 1)"
    echo "  -p   Pages per chunk (default: 10)"
    echo "  -b   Chandra batch size (default: 5)"
    echo "  -d   Project directory (default: $PROJECT_DIR)"
    exit 1
}

# -------- defaults --------
INPUT=""
BASE_OUT=""
START=1
END=0
STEP=10
BATCH_SIZE=5
METHOD="vllm"
PROJECT_DIR="/home/bhickta/development/chandra"
VENV="$PROJECT_DIR/.venv/bin/activate"

# -------- parse args --------
while getopts "i:o:s:e:p:b:d:m:" opt; do
    case $opt in
        i) INPUT="$OPTARG" ;;
        o) BASE_OUT="$OPTARG" ;;
        s) START="$OPTARG" ;;
        e) END="$OPTARG" ;;
        p) STEP="$OPTARG" ;;
        b) BATCH_SIZE="$OPTARG" ;;
        d) PROJECT_DIR="$OPTARG"
           VENV="$PROJECT_DIR/.venv/bin/activate" ;;
        m) METHOD="$OPTARG" ;;
        *) usage ;;
    esac
done

[[ -z "$INPUT" || -z "$BASE_OUT" || -z "$END" ]] && usage

# -------- normalize output base --------
BASE_OUT="${BASE_OUT%/}"

# If output is a directory, derive base name from input PDF
if [ -d "$BASE_OUT" ] || [[ "$BASE_OUT" != *_* && "$BASE_OUT" == */* ]]; then
    PDF_BASE="$(basename "$INPUT" .pdf)"
    PDF_BASE="$(echo "$PDF_BASE" | tr '[:upper:] ' '[:lower:]_')"
    BASE_OUT="$BASE_OUT/$PDF_BASE"
fi

# -------- environment --------
cd "$PROJECT_DIR" || exit 1
source "$VENV"

# -------- auto-resume --------
LAST_PAGE=0
for dir in "${BASE_OUT}"_*; do
    if [ -f "$dir/The Wonderland That is Himachal Pradesh/The Wonderland That is Himachal Pradesh.md" ]; then
        current_end="${dir##*-}"
        [[ "$current_end" =~ ^[0-9]+$ ]] && (( current_end > LAST_PAGE )) && LAST_PAGE=$current_end
    fi
done

if (( LAST_PAGE > 0 && START == 1 )); then
    START=$((LAST_PAGE + 1))
    echo "Resuming from page $START"
fi

# -------- processing --------
for ((i=START; i<=END; i+=STEP)); do
    j=$((i+STEP-1))
    (( j > END )) && j=$END

    OUTDIR="${BASE_OUT}_${i}-${j}"
    echo "Processing pages $i–$j → $OUTDIR"

    # Construct the base command
    CMD=(chandra "$INPUT" "$OUTDIR" --method "$METHOD" --batch-size "$BATCH_SIZE" --include-images --paginate_output --page-range "$i-$j")

    # Only add quantization flag if using 'hf' method (vllm handles it server-side)
    if [[ "$METHOD" == "hf" ]]; then
        CMD+=(--quantization 4bit)
    fi

    "${CMD[@]}"
done

