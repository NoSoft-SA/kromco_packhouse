#!/usr/bin/env bash

# Move masterfiles from one dir to another after prefixing the filenames with "MF".
# Parameters: 1: from_dir, 2: to_dir.
# If a file is compressed, it is extracted into a subdir named extracted.
# A second pass processes the extracted files.


INDIR=${1:-"/home/Kromco_MES/edi_masterfiles_in"}
OUTDIR=${2:-"/home/Kromco_MES/edi_in/receive"}

# INDIR=${1:-"/home/Kromco_MES/edi_masterfiles_in"}
# OUTDIR=${2:-"/home/Kromco_MES/edi_in/receive"}

if [ -d "$INDIR" ]
then
  cd "$INDIR"
else
  echo "The source folder "$INDIR" does not exist"
  exit 1
fi

if [ ! -d "$OUTDIR" ]
then
  echo "The target folder "$OUTDIR" does not exist"
  exit 1
fi

echo moving from "$INDIR" to "$OUTDIR" ...

# Loop twice: once for all files in the INDIR, once for any files that were extracted from zipped files.
for (( i=1; $i<=2; i++))
do
  # Second pass - change to the extracted subdir.
  if [ $i -eq 2 ]
  then
    echo Moving any files extracted in the previous pass...
    INDIR+="/extracted"
    cd "$INDIR"
  fi

  # Loop through the list of files in $INDIR.
  for FN in *
  do
    # Only process files (ignore subdirs).
    if [ -f "$FN" ] 
    then
      echo moving "$FN" as "MF$(basename "$FN")"

      # Test file to see if it is a Zip file:
      ZIPRES=$(file -b "$FN" | grep -i zip)

      # Success from the call above means we are dealing with a zipfile.
      if [ $? -eq 0 ]
      then
        # Unzip to subdir "extracted".
        unzip -o "$FN" -d extracted
        # Remove zipfile after it has been extracted.
        rm "$FN"
      else
        # Move the file to $OUTDIR.
        mv "$FN" "${OUTDIR}/MF$(basename "$FN")"
      fi
    fi

  done

done

# Success!
exit 0
