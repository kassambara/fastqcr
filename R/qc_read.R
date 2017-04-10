#' @include utilities.R
NULL
#' Read FastQC Data
#' @description Read FastQC data into R.
#' @param file Path to the file to be imported. Can be the path to either :
#' \itemize{
#'   \item the fastqc zipped file (e.g.: 'path/to/samplename_fastqc.zip'). No need to unzip,
#'   \item or the unzipped folder name (e.g.: 'path/to/samplename_fastqc'),
#'   \item or the sample name (e.g.: 'path/to/samplename' )
#'   \item or the fastqc_data.txt file,
#'   }
#' @param modules Character vector containing the names of FastQC modules for
#'   which you want to import/inspect the data. Default is all. Allowed values include
#'   one or the combination of:
#'   \itemize{
#'    \item "Summary",
#'    \item "Basic Statistics",
#'    \item "Per base sequence quality",
#'    \item "Per tile sequence quality",
#'    \item "Per sequence quality scores",
#'    \item "Per base sequence content",
#'    \item "Per sequence GC content",
#'    \item "Per base N content",
#'    \item "Sequence Length Distribution",
#'    \item "Sequence Duplication Levels",
#'    \item "Overrepresented sequences",
#'    \item "Adapter Content",
#'    \item "Kmer Content"
#'   }
#' Partial match of module names allowed. For example,
#' you can use modules = "GC content", instead of the full names modules = "Per sequence GC content".
#' @param verbose logical value. If TRUE, print filename when reading.
#' @return Returns a list of tibbles containing the data for specified modules.
#' @examples
#' # Demo file
#' qc.file <- system.file("fastqc_results", "S1_fastqc.zip",  package = "fastqcr")
#' qc.file
#' # Read all modules
#' qc_read(qc.file)
#'
#' # Read a specified module
#' qc_read(qc.file,"Per base sequence quality")
#'
#' @export
qc_read <- function(file, modules = "all", verbose = TRUE){

  . <- NULL
  modules <- .valid_fastqc_modules(modules)

  # file = "samplename"
  if(!.is_dir(file) & !.is_file(file)){
    .dirname <- dirname(file)
    .basename <- basename(file)
    # match zipped file
    file <- list.files(.dirname, pattern = paste0("^", .basename, "*_fastqc.zip"),
                       full.names = TRUE)
    # or match unzipped folder
    if(.is_empty(file))
      file <- dir(.dirname, pattern = paste0("^", .basename, "*_fastqc$"),
                        full.names = TRUE, include.dirs = TRUE)
    if(length(file) == 0)
      stop("Can't find any file that match: ", .basename)
    file <- file[1]
  }

  if(verbose) message("Reading: ", file)

  # file = "zipped file"
  if(.file_ext(file) == "zip"){
    raw.data <- .read_file_zip(file, "fastqc_data.txt")
    summary.data <- .read_file_zip(file, "summary.txt")
   }
  # file = "unzipped folder"
  else if(.is_dir(file)){
    raw.data <- readr::read_file(file.path(file, "fastqc_data.txt"))
    summary.data <- readr::read_file(file.path(file, "summary.txt"))
  }
  # file = "fastqc_data.txt"
  else if(.is_file(file)){
    raw.data <- readr::read_file(file)
    summary.data <- ""
  }

  if(summary.data != "")
  summary.data <- paste0(
    ">>Summary\n",
    "status\tmodule\tsample\n", # add header
    summary.data,
    ">>END_MODULE"
  )
  all.data <- paste0(raw.data, summary.data)


  all.data <- all.data %>%
    gsub("#", "", .) %>%
    gsub(">>", "", .) %>%
    strsplit("END_MODULE") %>%
    unlist()
  
  res <- lapply(modules,
                function(module, all.data){
                  index <- grep(module, all.data, ignore.case = TRUE)
                  skip <- ifelse(module == "Sequence Duplication Levels", 3, 2)
                  if(length(index) >0) readr::read_tsv(all.data[index[1]], skip = skip)
                  else tibble::tibble()
                },
                all.data
  )
  names(res) <- gsub(" ", "_", tolower(modules))
  if("Sequence Duplication Levels" %in% modules){
    index <- grep("Sequence Duplication Levels", all.data, ignore.case = TRUE)
    if(length(index) >0)
      res$total_deduplicated_percentage <- readr::read_tsv(all.data[index[1]], skip = 2, n_max = 0)%>%
        colnames(.) %>%
        .[2] %>%
        as.numeric() %>%
        round(., 2)
  }

  res <- structure(res, class = c("list", "qc_read"))

  res
}



