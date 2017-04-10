#' @include utilities.R
NULL
#'Build a QC Report
#'@description Create an HTML file containing FastQC reports of one or multiple 
#'  files. Inputs can be either a directory containing multiple FastQC reports 
#'  or a single sample FastQC report.
#'@param qc.path path to the FastQC reports. Allowed values include: \itemize{ 
#'  \item A path to a directory containing multiple zipped FastQC reports, \item
#'  Or a single sample zipped FastQC report.  Partial match is allowed for sample name.}
#'@param result.file path to the result file prefix (e.g., path/to/qc-result).
#'  Don't add the file extension.
#'@param experiment text specifying a short description of the experiment. For 
#'  example experiment = "RNA sequencing of colon cancer cell lines".
#'@param interpret logical value. If TRUE, adds the interpretation of each 
#'  module.
#'@param template a character vector specifying the path to an Rmd template. 
#'  file.
#'@param preview logical value. If TRUE, shows a preview of the report.
#' @examples
#' \dontrun{
#'# Demo QC Directory
#' qc.path <- system.file("fastqc_results", package = "fastqcr")
#' qc.path
#' 
#' # List of files in the directory
#' list.files(qc.path)
#' 
#' # Multi QC report
#' qc_report(qc.path, result.file = "~/Desktop/result")
#' 
#' # QC Report of one sample with plot interpretation
#'  qc.file <- system.file("fastqc_results", "S1_fastqc.zip", package = "fastqcr")
#'  qc_report(qc.file, result.file = "~/Desktop/result",
#'    interpret = TRUE)
#' }
#'
#'@export
qc_report <- function(qc.path, result.file, experiment = NULL,
                      interpret = FALSE, template = NULL, preview = TRUE)
  {

  # partial match of sample file name
  # file = "samplename"
  if(!.is_dir(qc.path) & !.is_file(qc.path)){
    .dirname <- dirname(qc.path)
    .basename <- basename(qc.path)
    # match zipped file
    qc.path <- list.files(.dirname, pattern = paste0("^", .basename, "*_fastqc.zip"),
                       full.names = TRUE)
    if(length(qc.path) == 0)
      stop("Can't find any file that match: ", .basename)
    qc.path <- qc.path[1]
  }
  
  if(!.path.exists(qc.path))
    stop("Specified QC path doesn't exist.")
  
  .create_dir(dirname(result.file))

  oldwd <- getwd()
  setwd(dirname(result.file))

  result.file <- paste(basename(result.file),
                       # format(Sys.time(), "_%Y_%m_%d"),
                       ".html", sep="")
  result.file <- file.path(getwd(), result.file)
  
  if(is.null(template)){
    if(.is_dir(qc.path)) 
      report_template <- system.file("report_templates", 
                                     "multi-qc-report.Rmd", package = "fastqcr")
    else if(.is_file(qc.path)){
      report_template <- system.file("report_templates", 
                                     ifelse(interpret, "sample-report-interpret.Rmd", "sample-report.Rmd" ),
                                     package = "fastqcr")
    }
  }
  else 
    report_template <- template

  rmarkdown::render(input = report_template, output_file = result.file,
                    params = list(qc.path = qc.path, experiment = experiment))
  if(preview) .preview_site(result.file)
  
  message("\n--------------------------\nOutput file: ", 
          result.file, "\n--------------------------\n")

  setwd(oldwd)
}

