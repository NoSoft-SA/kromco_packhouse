#!/usr/bin/env bash

# Move edi files from one dir to another.
# Parameters: 1: from_dir, 2: to_dir.
# If a file is compressed, it is extracted to the second dir and the zip file is deleted.
# If a file has the ".inuse" extension it is ignored.

INDIR=${1:-"/home/james/edi_test/zipsplus"}
OUTDIR=${2:-"/home/james/edi_test/edi_in"}

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

echo
echo `date`
echo moving from "$INDIR" to "$OUTDIR" ...

  # Loop through the list of files in $INDIR.
  for FN in *
  do
    # Only process files (ignore subdirs).
    if [ -f "$FN" ] 
    then

      if [[ "$FN" == *.inuse ]]
      then
        echo skipping "$FN" while still in process of downloading
      else
        # Test file to see if it is a Zip file:
        ZIPRES=$(file -b "$FN" | grep -i zip)

        # Success from the call above means we are dealing with a zipfile.
        if [ $? -eq 0 ]
        then
          echo unzipping "$FN"
          # Unzip to $OUTDIR.
          unzip -o "$FN" -d "$OUTDIR"
          # Remove zipfile after it has been extracted.
          rm "$FN"
        else
          echo moving "$FN"
          # Move the file to $OUTDIR.
          mv "$FN" "${OUTDIR}/$(basename "$FN")"
        fi
      fi
    fi

  done

# Success!
exit 0

