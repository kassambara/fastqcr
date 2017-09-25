#' Plot GC content of a collection of samples
#' 
#' A working example of a function to plot the GC content of multiple samples as multiple lines.
#' 
#' @param qc An object of class qc_read_collection
#' @param ggtheme A plotting themem
#' @param ... Other
#'
#' @return A graph of mulitple lines each corresponds to the GC content from one sample.
#' 
#' @examples 
#' # extract paths to the demo files
#' qc.dir <- system.file("fastqc_results", package = "fastqcr")
#' qc.files <- list.files(qc.dir, full.names = TRUE)
#' 
#' # read all modules in all files
#' qc <- qc_read_collection(qc.files, sample_names = paste('S', 1:5, sep = ''))
#' 
#' # plot GC content in all samples
#' plot_gc_content_collection(qc)
#' 
#' @export
plot_gc_content_collection <- function(qc, ggtheme = theme_minimal(), ...){
  .names <- names(qc)
  if(!("per_sequence_gc_content" %in% .names))
    return(NULL)
  
  d <- qc$per_sequence_gc_content
  if(nrow(d) == 0) return(NULL)
  colnames(d) <- make.names(colnames(d))
  ggplot(d, aes_string(x = "GC.Content", y = "Count", color = 'sample'))+
    geom_line() +
    labs(title = "Per sequence GC content", x = "Mean GC Content (%)")+
    theme_minimal()
  }
