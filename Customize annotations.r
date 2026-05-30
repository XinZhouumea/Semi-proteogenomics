library(customProDB)
library(biomaRt)
library(httr)

# --- 1. EXTEND TIMEOUTS ---
options(timeout = 600)
try(httr::set_config(httr::timeout(600)), silent = TRUE)

# --- 2. PATCH A: The Rat Gene Wiretap (This is working perfectly) ---
try(untrace(biomaRt::getBM), silent = TRUE)
trace(biomaRt::getBM, print = FALSE, tracer = quote({
  if ("hgnc_symbol" %in% attributes) {
    attributes[attributes == "hgnc_symbol"] <- "external_gene_name"
  }
}))

# --- 3. PATCH B: The Universal "Archive" Annihilator ---
# This destroys the illegal 'archive' argument across ALL biomaRt functions
# hidden inside the memory of EVERY background package.

destroy_archive_bug <- function(fn_name) {
  # Get the real function
  if (!exists(fn_name, envir = asNamespace("biomaRt"))) return()
  real_fn <- get(fn_name, envir = asNamespace("biomaRt"))
  
  # Create a wrapper that deletes 'archive' before it runs
  safe_fn <- function(...) {
    args <- list(...)
    args$archive <- NULL 
    do.call(real_fn, args)
  }
  
  # 1. Lock it into the main biomaRt package
  unlockBinding(fn_name, asNamespace("biomaRt"))
  assign(fn_name, safe_fn, envir = asNamespace("biomaRt"))
  lockBinding(fn_name, asNamespace("biomaRt"))
  
  # 2. Break into the hidden Imports Vault of EVERY loaded package and overwrite
  for (pkg in loadedNamespaces()) {
    ns <- asNamespace(pkg)
    imp <- parent.env(ns)
    if (exists(fn_name, envir = imp, inherits = FALSE)) {
      unlockBinding(fn_name, imp)
      assign(fn_name, safe_fn, envir = imp)
      lockBinding(fn_name, imp)
    }
  }
}

# Annihilate the bug in every function the background packages might use
destroy_archive_bug("useMart")
destroy_archive_bug("listMarts")
destroy_archive_bug("listDatasets")
destroy_archive_bug("listEnsembl")
# --------------------------------------------------------

# --- 4. RUN THE PIPELINE ---
output_dir <- "D:/Xin/Ensembl_Rat_rn6"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

cat("Connecting to Ensembl Archive (Nov 2020) for Rat rn6...\n")
rat_mart <- biomaRt::useMart(
  biomart = "ENSEMBL_MART_ENSEMBL", 
  dataset = "rnorvegicus_gene_ensembl", 
  host = "https://nov2020.archive.ensembl.org"
)

cat("Compiling annotations... Smashing through the final bugs!\n")
PrepareAnnotationEnsembl(
  mart = rat_mart, 
  annotation_path = output_dir, 
  splice_matrix = FALSE,  
  dbsnp = NULL,           
  COSMIC = FALSE          
)

cat("Success! Your 4 RData files are ready in:", output_dir, "\n")