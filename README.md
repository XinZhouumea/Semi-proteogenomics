# CustomProDB Rat (rn6) Annotation Generator & Bugfix Patch

This script generates the four required `.RData` annotation files (`exon_anno`, `ids`, `proseq`, `procodingseq`) needed to run the **CustomProDB** proteomics pipeline using the **Rat (Rnor_6.0 / rn6)** reference genome.

It specifically connects to the Ensembl Time Machine Archive (November 2020, Release 104) to guarantee the `rn6` build rather than the newer `rn7` build.

You can customize the reference genome for your own project requirements. Below is an example of how to connect to a specific Ensembl archive using R:

cat("Connecting to Ensembl Archive (Nov 2020) for Rat rn6...\n")
rat_mart <- biomaRt::useMart(
  biomart = "ENSEMBL_MART_ENSEMBL", 
  dataset = "rnorvegicus_gene_ensembl", 
  host = "https://nov2020.archive.ensembl.org"
)

## ⚠️ The Problems This Script Solves

CustomProDB is a powerful tool, but it suffers from severe "package rot" and was originally designed strictly for human data. If you attempt to run standard `PrepareAnnotationEnsembl()` for rat data on modern versions of R, it will suffer cascading crashes.

This script deploys two major runtime patches to force the package to work:

1. **The Human Gene Bug (`hgnc_symbol`):** CustomProDB hardcodes a request for Human Gene Nomenclature (`hgnc_symbol`). When Ensembl sees this request for a Rat genome, it crashes.
* *The Patch:* The script places a wiretap on the `biomaRt::getBM` function, intercepting the request in real-time and silently swapping it to the rat-compatible `external_gene_name`.


2. **The Deprecated Archive Bug (`archive = FALSE`):** Deep inside `customProDB` and its background dependencies (`GenomicFeatures`, `txdbmaker`), functions attempt to pass the argument `archive = FALSE` to Ensembl. Modern R removed this argument, causing an `unused argument` crash.
* *The Patch:* The script deploys a Universal Namespace Override. It breaks into the hidden memory vaults of every loaded background package and strips the `archive` argument out of every Ensembl database function before it can trigger a crash.



## 📦 Prerequisites

You must have R installed, along with the following Bioconductor/CRAN packages:

* `customProDB`
* `biomaRt`
* `httr`
* `GenomicFeatures`

## 🚀 How to Run

1. **Clear Your Environment:** It is highly recommended to restart your R session or clear your environment completely before running this script to ensure old, unpatched package memory doesn't interfere.
2. **Set Your Output Directory:** By default, the script outputs to `D:/Xin/Ensembl_Rat_rn6`. You can change the `output_dir` variable on line 43 if you need to save it elsewhere.
3. **Execute:** Run the entire script at once.
4. **Wait:** Ensembl Archive servers can be slow. It may take 5–10 minutes to download and compile the coordinate maps and sequence files. The script extends R's native timeout limit to 10 minutes to prevent premature disconnects.

## 📂 Output Files & Galaxy Mapping

Once the script prints `Success!`, you will find four `.RData` files in your output directory.

When uploading these to **Galaxy** to use with the CustomProDB tool, **do not let Galaxy auto-fill the same file multiple times.** You must map them exactly 1-to-1 in the tool interface:

| CustomProDB Tool Input | Corresponding File to Select |
| --- | --- |
| **Exon Annotations** | `exon_anno.RData` |
| **Protein Sequences** | `proseq.RData` |
| **Protein Coding Sequences** | `procodingseq.RData` |
| **Protein IDs** | `ids.RData` |

## 🛠️ Troubleshooting

* **Error: `Timeout was reached**`
* *Cause:* The Ensembl Archive server (`nov2020.archive.ensembl.org`) took too long to respond.
* *Fix:* Simply run the script again. The servers occasionally experience heavy traffic.


* **Error: `unused argument (archive = FALSE)**`
* *Cause:* A package loaded a fresh, unpatched copy of `biomaRt` into memory.
* *Fix:* Completely restart your R session to clear the memory vaults, then run the script from top to bottom.
