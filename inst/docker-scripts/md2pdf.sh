#!/bin/bash
#
# Convert Markdown to PDF
#
# Syntax:
#
# md2pdf.sh

dirname2render=$(dirname ${file2render})
basename2render=$(basename ${file2render})

input_dirname=$dirname2render/${basename2render%.*}
input_basename=index.md

cd /home/mambauser/andrew/$input_dirname

# Need to move the .qmd file
# Workaround for https://github.com/quarto-dev/quarto-cli/issues/6583
tmp_dir=$(mktemp -d)
mv *.qmd $tmp_dir

cat > _quarto.yml <<'EOF'
format:
  pdf:
    pdf-engine: lualatex
    papersize: a4
    geometry:
      - top=25mm
      - bottom=20mm
      - left=25mm
      - right=25mm
    fontsize: '10'
    classoption:
      - DIV=10
      - numbers=noendperiod
    include-in-header:
      - text: |
          \usepackage{luatexja}
          \usepackage{fvextra}
          \usepackage{longtable}
          \fvset{breaklines=true,breakanywhere=true}
          \AtBeginEnvironment{verbatim}{\scriptsize}
          \AtBeginEnvironment{longtable}{\tiny\setlength{\tabcolsep}{1pt}}
EOF

# cleaning up scripts and links
cp $input_basename markdown-render-pdf.md

sed -i '/^\s*<script[^>]*>/d' markdown-render-pdf.md
sed -i '/^\s*<link[^>]*>/d' markdown-render-pdf.md

quarto \
    render markdown-render-pdf.md \
    --to pdf \
    --output index.pdf

rm _quarto.yml markdown-render-pdf.md

# Need to move the .qmd file back
mv $tmp_dir/*.qmd .
