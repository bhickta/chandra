import os
import re
from pathlib import Path

def join_files():
    base_dir = Path("/home/bhickta/development/chandra/assets/output")
    output_file = base_dir / "combined_wonderland.md"
    
    # Pattern to match directories like 'wonderland_that_is_hp_1-10'
    dirname_pattern = re.compile(r"(.+)_(\d+)-(\d+)$")
    # Pattern to match page separators e.g. "2------------------------------------------------"
    page_sep_pattern = re.compile(r"^\d+-+$", re.MULTILINE)
    
    dirs = []
    
    if not base_dir.exists():
        print(f"Directory not found: {base_dir}")
        return

    print(f"Scanning {base_dir}...")

    for item in os.listdir(base_dir):
        path = base_dir / item
        if path.is_dir():
            match = dirname_pattern.match(item)
            if match:
                start_page = int(match.group(2))
                end_page = int(match.group(3))
                dirs.append({
                    'path': path,
                    'start': start_page,
                    'end': end_page,
                    'name': item
                })
    
    # Sort by start page
    dirs.sort(key=lambda x: x['start'])
    
    if not dirs:
        print("No matching directories found.")
        return

    print(f"Found {len(dirs)} directories. Verifying continuity...")
    
    missing_ranges = []
    last_end = 0
    
    if dirs[0]['start'] != 1:
        print(f"WARNING: Sequence starts at page {dirs[0]['start']}, potentially missing 1-{dirs[0]['start']-1}")
        missing_ranges.append(f"1-{dirs[0]['start']-1}")
        last_end = dirs[0]['start'] - 1
    else:
        last_end = 0

    for d in dirs:
        if d['start'] > last_end + 1:
            gap_start = last_end + 1
            gap_end = d['start'] - 1
            print(f"MISSING RANGE: Gap detected between {gap_start} and {gap_end}")
            missing_ranges.append(f"{gap_start}-{gap_end}")
        last_end = d['end']

    merged_content = []
    errors_found = False
    
    print("\nProcessing files and verifying page counts...")
    
    for d in dirs:
        inner_book_dir = d['path'] / "The Wonderland That is Himachal Pradesh" 
        md_file = inner_book_dir / "The Wonderland That is Himachal Pradesh.md"
        
        if not md_file.exists():
            # Fallback scan
            found = list(d['path'].glob("**/*.md"))
            if found:
                md_file = found[0]
            else:
                print(f"ERROR: No MD file found in {d['name']} (Expected {d['start']}-{d['end']})")
                errors_found = True
                continue
                
        try:
            with open(md_file, "r", encoding="utf-8") as f:
                content = f.read()
                
            # Verify page count
            # Count separators. If pages are 1-10, we expect usually markers 2..10 (9 markers) + implicit page 1.
            # So expected count approx (end - start + 1).
            # Markers found = M. Estimated pages = M + 1 (usually).
            
            separators = page_sep_pattern.findall(content)
            marker_count = len(separators)
            estimated_pages = marker_count + 1 # Assuming first page has no top marker or we count content blocks
            
            expected_pages = d['end'] - d['start'] + 1
            
            # Heuristic: If mismatch is large (> 2 pages), warn.
            # Note: Sometimes blank pages are skipped or merged.
            
            if abs(estimated_pages - expected_pages) > 2:
                 print(f"WARNING: {d['name']} ({d['start']}-{d['end']}): Expected {expected_pages} pages, found ~{estimated_pages} (markers: {marker_count})")
            
            merged_content.append(content)
            
        except Exception as e:
            print(f"Error reading {md_file}: {e}")
            errors_found = True

    if missing_ranges:
        print("\nCRITICAL: Missing page ranges detected!")
        for gap in missing_ranges:
            print(f" - Missing: {gap}")
        errors_found = True

    if errors_found:
        print("\nABORTING: Errors were found (missing files or gaps). No output file created.")
        print("Please fix the missing chunks/files and run again.")
        return

    # Write output if no errors
    with open(output_file, "w", encoding="utf-8") as out:
        out.write("\n\n".join(merged_content))
        
    print(f"\nSUCCESS: Joined {len(merged_content)} chunks into {output_file}")
    print("All page counts seemingly within expected range.")

if __name__ == "__main__":
    join_files()

