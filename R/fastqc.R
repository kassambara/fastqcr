#' @include utilities.R
NULL
#' Run FastQC Tool
#' @description Run FastQC Tool
#' @param fq.dir path to the directory containing fastq files. Default is the
#'   current working directory.
#' @param qc.dir path to the FastQC result directory. If NULL, a directory
#'   named fastqc_results is created in the current working directory.
#' @param threads the number of threads to be used. Default is 4.
#' @rdname fastqc
#' @return Create a directory containing the reports
#' @examples
#' \dontrun{
#' # Run FastQC: generates a QC directory
#' fastqc(fq.dir)
#' }
#' @export
fastqc <- function(fq.dir = getwd(),   qc.dir = NULL, threads = 4){
  .check_if_unix()
  if(is.null(qc.dir)) qc.dir <- file.path(fq.dir, "FASTQC")
  .create_dir(qc.dir)
  cmd <- paste0("fastqc ", fq.dir, "/*  --threads ", threads,  " --outdir ", qc.dir)
  system(cmd)
}
