#!/bin/bash

# Rename .sol files to .txt in flattened folder
for f in src/flattened/*.sol; do
  [ -f "$f" ] && mv "$f" "${f%.sol}.txt"
done

# Run forge doc
forge clean && forge b && forge doc --build --out ./docs/forge-docs

# Capture exit code
RESULT=$?

# Rename .txt files back to .sol
for f in src/flattened/*.txt; do
  [ -f "$f" ] && mv "$f" "${f%.txt}.sol"
done

# Exit with the captured exit code
exit $RESULT
