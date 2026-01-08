INPUT="assets/input/The Wonderland That is Himachal Pradesh.pdf"
BASE_OUT="assets/output/wonderland_that_is_hp"

# Detect last processed page to resume
LAST_PAGE=0
for dir in "${BASE_OUT}"_*; do
    if [ -d "$dir" ]; then
        # Check if directory actually contains the completion marker (metadata file or markdown)
        # This is safer to ensure we don't skip failed batches
        if [ -f "$dir/The Wonderland That is Himachal Pradesh/The Wonderland That is Himachal Pradesh.md" ]; then
             # Extract end page number
             # Format: ..._start-end
             current_end="${dir##*-}"
             if [[ "$current_end" =~ ^[0-9]+$ ]]; then
                 if (( current_end > LAST_PAGE )); then
                     LAST_PAGE=$current_end
                 fi
             fi
        fi
    fi
done

if (( LAST_PAGE > 0 )); then
    START=$((LAST_PAGE + 1))
    echo "Resuming from page $START (found output up to $LAST_PAGE)"
else
    START=1
fi
END=100
STEP=10

for ((i=START; i<=END; i+=STEP)); do
    j=$((i+STEP-1))
    if [ $j -gt $END ]; then
        j=$END
    fi

    OUTDIR="${BASE_OUT}_${i}-${j}"

    echo "Processing pages $i to $j → $OUTDIR"
    uv run \
    chandra \
      "$INPUT" \
      "$OUTDIR" \
      --quantization 4bit \
      --method hf \
      --batch-size 5 \
      --include-images \
      --paginate_output \
      --page-range "$i-$j"
done