#' @include utilities.R
NULL
#' Aggregate FastQC Reports for Multiple Samples
#' @description Aggregate multiple FastQC reports into a data frame.
#' @param qc.dir path to the FastQC result directory to scan. 
#' @param progressbar logical value. If TRUE, shows a progress bar.
#' @describeIn qc_aggregate Aggregate FastQC Reports for Multiple Samples
#' @return
#' \itemize{
#'     \item \strong{qc_aggregate()} returns an object of class qc_aggregate
#'     which is a (tibble) data frame with the following column names:
#'          \itemize{
#'          \item sample: sample names
#'          \item module: fastqc modules
#'          \item status: fastqc module status for each sample
#'          \item tot.seq: total sequences (i.e.: the number of reads)
#'          \item seq.length: sequence length
#'          \item pct.gc: \% of GC content
#'          \item pct.dup: \% of duplicate reads
#'          }
#'    \item \strong{summary}: Generates a summary of qc_aggregate.
#'    Returns a data frame with the following columns:
#'    \itemize{
#'    \item module: fastqc modules
#'    \item nb_samples: the number of samples tested
#'    \item nb_pass, nb_fail, nb_warn: the number of samples that passed, failed and warned, respectively.
#'    \item failed, warned: the name of samples that failed and warned, respectively.
#'    }
#'    \item \strong{qc_stats}: returns a data frame containing general statistics of fastqc reports.
#'    columns are: sample, pct.dup, pct.gc, tot.seq and seq.length.
#'   }
#' @examples
#' # Demo QC dir
#' qc.dir <- system.file("fastqc_results", package = "fastqcr")
#' qc.dir
#' 
#' # List of files in the directory
#' list.files(qc.dir)
#'
#' # Aggregate the report
#' qc <- qc_aggregate(qc.dir, progressbar = FALSE)
#' qc
#'
#' # Generates a summary of qc_aggregate
#' summary(qc)
#' 
#' # General statistics of fastqc reports.
#' qc_stats(qc)
#' 
#' @export
qc_aggregate <- function(qc.dir = ".", progressbar = TRUE)
{
  ## List f files
  qc.files <- list.files(qc.dir, pattern = "fastqc.zip",
                         full.names = TRUE, recursive = TRUE)
  nfiles <- length(qc.files)
  if(nfiles == 0)
    stop("Can't find any *fastqc.zip files in the specified qc.dir")
  
  ## Aggregate
  res.summary <- NULL
  progressbar <- progressbar & nfiles >3
  if(progressbar) {
    message("Aggregating FastQC Outputs \n")
    pb <- utils::txtProgressBar(max = nfiles, style = 3)
  }
  for(i in 1:nfiles){
    
    qc <- qc_read(qc.files[i], modules = c("summary", "statistics", "Sequence Duplication Levels"),
                  verbose = FALSE)
    .summary <- qc$summary # Summary for each sample
    .statistics <- as.data.frame(qc$basic_statistics) # Basic statistics
    rownames(.statistics) <- .statistics$Measure
    pct.dup <- round(100 - qc$total_deduplicated_percentage, 2) # Sequence Duplication Levels
    
    .summary <- dplyr::mutate(.summary,
                              tot.seq= rep(.statistics["Total Sequences", 2], nrow(.summary)),
                              pct.gc = as.numeric(rep(.statistics["%GC", 2], nrow(.summary))),
                              seq.length = rep(.statistics["Sequence length", 2], nrow(.summary)),
                              pct.dup = rep(pct.dup, nrow(.summary))
    )
    res.summary <- rbind(res.summary, .summary)
    if(progressbar) utils::setTxtProgressBar(pb, i)
  }
  res.summary <- dplyr::select(
    res.summary, 
    dplyr::all_of(c("sample", "module", "status","tot.seq", "seq.length", "pct.gc", "pct.dup"))
    )
  res.summary$sample <-gsub(".fastq.gz|.fastq", "", res.summary$sample,
                            ignore.case = TRUE)
  
  if(progressbar) close(pb)
  
  res.summary <- structure(res.summary, class = c("qc_aggregate", class(res.summary)) )
  res.summary
}

#' @param object an object of class qc_aggregate.
#' @param ... other arguments.
#' @method summary qc_aggregate
#' @rdname qc_aggregate
#' @export
summary.qc_aggregate <- function(object, ...){
  
  module <- status <- nb_samples <- sample <- NULL
  
  # For each module, count the number of samples that pass, fail and warn
  res <- object %>%
    dplyr::group_by(module, status) %>%
    dplyr::summarise(count = n()) %>%
    tidyr::spread(key = "status", value = "count", fill = 0)
  colnames(res) <- tolower(colnames(res))
  colnames(res)[2:ncol(res)] <- paste0("nb_", colnames(res)[-1])
  
  res <- res %>%
    dplyr::mutate(nb_samples = rowSums(res[, -1])[1]) %>%
    dplyr::select(module, nb_samples, everything())
  # Add sample names that fail
  failed <- qc_fails(object, element = "module") %>%
    select(module, sample) %>%
    dplyr::rename(failed = sample)
  if(nrow(failed) >0) res <- left_join(res, failed, by = "module")
  # Add sample names that warn
  warned <- qc_warns(object, element = "module") %>%
    select(module, sample) %>%
    dplyr::rename(warned = sample)
  if(nrow(warned) >0) res <- left_join(res, warned, by = "module")
  res
}


#' @describeIn qc_aggregate Creates general statistics of fastqc reports.
#' @export
qc_stats <- function(object){
  .check_object(object)
  sample <- pct.dup <- pct.gc <- tot.seq <- seq.length <- NULL
  res <- object %>%
    select(sample, pct.dup, pct.gc, tot.seq, seq.length) %>%
    distinct(sample, .keep_all = TRUE)
  res
}

.check_object <- function(object){
  if(!inherits(object, "qc_aggregate"))
    stop("An object of class qc_aggregate required.")
}
