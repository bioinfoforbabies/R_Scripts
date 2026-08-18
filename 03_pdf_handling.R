# 3. Merge or split PDFs
# Card: "Combine or Split PDFs Without Opening an App"

# install.packages("pdftools")
library(pdftools)

## Merge several PDFs into one
pdf_files <- c("report_1.pdf", "report_2.pdf", "report_3.pdf")
pdf_combine(pdf_files, output = "combined_report.pdf")

## Split a PDF into individual pages
pdf_split("combined_report.pdf", output = "page_")
# creates page_1.pdf, page_2.pdf, ...