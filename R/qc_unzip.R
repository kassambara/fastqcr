#' @include utilities.R
NULL
#' Unzip Files in the FastQC Result Directory
#' @description Unzip all files in the FastQC result directory. Default is the
#'   current working directory.
#' @param qc.dir Path to the FastQC result directory.
#' @param rm.zip logical. If TRUE, remove zipped files after extraction. Default
#'   is TRUE.
#' @examples
#' \dontrun{
#' qc_unzip("FASTQC")
#' }
#' @export
qc_unzip <- function(qc.dir = ".", rm.zip = TRUE){
  zipped.files <- list.files(qc.dir, pattern = ".zip",
                             full.names = TRUE)
  for(zipped.file in zipped.files){
    utils::unzip(zipped.file, exdir = qc.dir)
    if(rm.zip) .remove(zipped.file)
  }
}

