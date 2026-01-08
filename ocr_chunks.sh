INPUT="assets/input/The Wonderland That is Himachal Pradesh.pdf"
BASE_OUT="assets/output/wonderland_that_is_hp"

START=1
END=2
STEP=50

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
      --batch-size 2 \
      --include-images \
      --paginate_output \
      --page-range "$i-$j"
done