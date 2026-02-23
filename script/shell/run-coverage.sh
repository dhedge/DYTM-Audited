#!/bin/bash

# Rename .sol files to .txt in flattened folder
for f in src/flattened/*.sol; do
  [ -f "$f" ] && mv "$f" "${f%.sol}.txt"
done

# Run coverage
forge coverage --report lcov --ir-minimum --no-match-coverage '(test|script)/**/*.sol' \
  && lcov --remove lcov.info 'test/*' 'script/*' --output-file lcov.info --rc branch_coverage=1 --ignore-errors inconsistent --ignore-errors unused \
  && genhtml lcov.info --branch-coverage --ignore-errors corrupt --ignore-errors inconsistent --output-dir coverage

# Capture exit code
RESULT=$?

# Rename .txt files back to .sol
for f in src/flattened/*.txt; do
  [ -f "$f" ] && mv "$f" "${f%.txt}.sol"
done

# Exit with the captured exit code
exit $RESULT
