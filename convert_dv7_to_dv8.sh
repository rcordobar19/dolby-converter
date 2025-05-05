#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <directory_path>"
    exit 1
fi
targetDir="$1"

doviTool="/usr/local/bin/dovi_tool"
mkvextract="/usr/bin/mkvextract"
mkvmerge="/usr/bin/mkvmerge"
mediainfo="/usr/bin/mediainfo"
jsonConfig="/app/DV7toDV8-CMv40.json"

for tool in "$doviTool" "$mkvextract" "$mkvmerge" "$mediainfo"; do
    if [[ ! -x "$tool" ]]; then
        echo "Error: $tool not found or not executable"
        exit 1
    fi
done

if [[ ! -d "$targetDir" ]]; then
    echo "Error: Directory not found: $targetDir"
    exit 1
fi

if [[ ! -f "$jsonConfig" ]]; then
    echo "Error: JSON config not found: $jsonConfig"
    exit 1
fi

echo "Starting DV Profile 7 to 8 conversion in $targetDir..."

# Find all MKV files
mapfile -t mkvFiles < <(find "$targetDir" -type f -iname "*.mkv")
totalFiles=${#mkvFiles[@]}
if [[ $totalFiles -eq 0 ]]; then
    echo "No MKV files found in $targetDir. Exiting."
    exit 0
fi

processedFiles=0

for inputFile in "${mkvFiles[@]}"; do
    ((processedFiles++))
    baseName=$(basename "$inputFile" .mkv)
    dirName=$(dirname "$inputFile")
    hevcFile="$dirName/$baseName.BL_EL_RPU.hevc"
    dv8File="$dirName/$baseName.DV8.BL_RPU.hevc"
    outputFile="$dirName/$baseName.DV8.mkv"

    echo "Processing file $processedFiles of $totalFiles: $inputFile"

    dvFormat=$("$mediainfo" "$inputFile" | grep "HDR format" | grep "Dolby Vision" | sed 's/HDR format\s*:\s*//')
    if [[ ! "$dvFormat" =~ "Profile 7" || ! "$dvFormat" =~ "BL+EL+RPU" ]]; then
        echo "Not a DV Profile 7 (BL+EL+RPU) file: $dvFormat. Skipping."
        continue
    fi
    echo "Confirmed DV7: $dvFormat"

    echo "Extracting HEVC with mkvextract..."
    "$mkvextract" "$inputFile" tracks 0:"$hevcFile"
    if [[ $? -ne 0 || ! -f "$hevcFile" ]]; then
        echo "Error: mkvextract failed"
        [[ -f "$hevcFile" ]] && rm -f "$hevcFile"
        continue
    fi
    echo "Extracted: $hevcFile, size: $(stat -c%s "$hevcFile") bytes"

    echo "Converting to DV8 with dovi_tool and config"
    "$doviTool" --edit-config "$jsonConfig" convert --discard "$hevcFile" -o "$dv8File"
    if [[ $? -ne 0 || ! -f "$dv8File" ]]; then
        echo "Error: dovi_tool conversion failed"
        [[ -f "$hevcFile" ]] && rm -f "$hevcFile"
        [[ -f "$dv8File" ]] && rm -f "$dv8File"
        continue
    fi
    echo "Converted: $dv8File, size: $(stat -c%s "$dv8File") bytes"

    echo "Remuxing to MKV..."
    "$mkvmerge" -o "$outputFile" -D "$inputFile" "$dv8File" --track-order 1:0
    if [[ $? -ne 0 || ! -f "$outputFile" ]]; then
        echo "Error: mkvmerge failed"
        [[ -f "$hevcFile" ]] && rm -f "$hevcFile"
        [[ -f "$dv8File" ]] && rm -f "$dv8File"
        continue
    fi
    echo "Output: $outputFile"

    echo "Verifying output with MediaInfo..."
    finalFormat=$("$mediainfo" "$outputFile" | grep "HDR format" | grep "Dolby Vision" | sed 's/HDR format\s*:\s*//')
    if [[ ! "$finalFormat" =~ "Profile 8" ]]; then
        echo "Error: Output not Profile 8: $finalFormat"
        [[ -f "$hevcFile" ]] && rm -f "$hevcFile"
        [[ -f "$dv8File" ]] && rm -f "$dv8File"
        [[ -f "$outputFile" ]] && rm -f "$outputFile"
        continue
    fi
    echo "Verified DV8: $finalFormat"

    rm -f "$hevcFile" "$dv8File"
    echo "Successfully converted: $outputFile"
done

echo "Conversion completed. Processed $processedFiles of $totalFiles files."
