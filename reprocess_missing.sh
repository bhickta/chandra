#!/usr/bin/env bash

# Activate environment
cd /home/bhickta/development/chandra || exit 1
source /home/bhickta/development/chandra/.venv/bin/activate

INPUT="assets/input/The Wonderland That is Himachal Pradesh.pdf"
BASE_OUT="assets/output/wonderland_that_is_hp"

# List of missing ranges provided by the user/join script
RANGES=(
"151-160"
"421-430"
"531-540"
"601-610"
"701-710"
"721-730"
"751-760"
"921-930"
"971-980"
"1061-1070"
"1071-1080"
"1081-1090"
"1091-1100"
"1101-1110"
"1111-1120"
"1121-1130"
"1141-1150"
"1201-1210"
"1251-1260"
"1321-1330"
"1351-1360"
"1371-1380"
"1611-1620"
"1641-1650"
)

for range in "${RANGES[@]}"; do
    OUTDIR="${BASE_OUT}_${range}"
    echo "Reprocessing range: $range -> $OUTDIR"
    
    # Remove empty directory if it causes issues, or let chandra overwrite/handle it
    # chandra seems to handle existing dirs, but let's be safe if it crashed before
    
    chandra \
      "$INPUT" \
      "$OUTDIR" \
      --quantization 4bit \
      --method hf \
      --batch-size 5 \
      --include-images \
      --paginate_output \
      --page-range "$range"
      
    echo "Finished $range"
    echo "--------------------------------"
done
