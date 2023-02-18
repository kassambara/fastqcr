#' Read a collection of FastQC data files
#' 
#' A wrapper function around \link{qc_read} to read multiple FastQC data files at once.
#'
#' @param files A \code{character} vector of paths to the files to be imported.
#' @param sample_names A \code{character} vector of length equals that of the first argument \code{files}
#' @inheritParams qc_read
#'
#' @author Mahmoud Ahmed, \email{mahmoud.s.fahmy@students.kasralainy.edu.eg}
#'
#' @return A \code{list} of \code{tibbles} containing the data of specified modules form each file.
#' 
#' @examples 
#' # extract paths to the demo files
#' qc.dir <- system.file("fastqc_results", package = "fastqcr")
#' qc.files <- list.files(qc.dir, full.names = TRUE)[1:2]
#' nb_samples <- length(qc.files)
#' 
#' 
#' # read a specified module in all files
#' # To read all modules, specify: modules = "all"
#' qc <- qc_read_collection(qc.files, 
#'     sample_names = paste('S', 1:nb_samples, sep = ''),
#'     modules = "Per base sequence quality")
#' 
#' @export
qc_read_collection <- function(files, sample_names, modules = 'all', verbose = TRUE) {
    # read module data by applying qc_read to files individually  
    module_data <- lapply(files,
                          qc_read,
                          modules = modules,
                          verbose = verbose)
    
    # make sample_names in case missing or 
    # with length unequal length of files
    if(missing(sample_names) || length(sample_names) != length(files)) {
       sample_names <- lapply(module_data,
                              function(x) unique(x$summary))
       sample_names <- unlist(sample_names)
    }
    
    # rename lists with sample_names
    names(module_data) <- sample_names
    
    # extract module_names 
    module_names <- unique(unlist(lapply(module_data, names)))
    
    # collect data of each module in a data.frame
    res <- list()
    for(i in seq_along(module_names)){
        res[[i]] <- lapply(module_data,
                         function(x) as.data.frame(x[[module_names[i]]]))
    }
    
    # rename modules using module names
    names(res) <- module_names

    # bind rows of test data.frames in the list
    res <- lapply(res,
                  dplyr::bind_rows, .id = 'sample')
    
    res <- structure(res,
                     class = c("list", "qc_read_collection"))
    
    res
}
