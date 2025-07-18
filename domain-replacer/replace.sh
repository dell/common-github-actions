set -e

echo "Scanning for files to update..."


find . -type f ! -name "go.sum"  ! -path "./domain-replacer/*" ! -path "./.github/workflows/*" | while read -r file; do
  echo "Checking $file"
  if grep -q 'github.com/dell/' "$file"; then
    echo "Updating $file"
    sed -i 's|github.com/dell/|eos2git.cec.lab.emc.com/CSM/|g' "$file"
  fi
done