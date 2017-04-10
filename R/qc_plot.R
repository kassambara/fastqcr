#' @include utilities.R
#' @importFrom ggplot2 ggplot
#' @importFrom ggplot2 aes
#' @importFrom ggplot2 aes_string
#' @importFrom ggplot2 geom_line
#' @importFrom ggplot2 theme_minimal
#' @importFrom ggplot2 coord_cartesian
#' @importFrom ggplot2 labs
#' @importFrom ggplot2 theme
#' @importFrom ggplot2 expand_limits
#' @importFrom ggplot2 geom_rect
#' @importFrom ggplot2 scale_x_discrete
#' @importFrom ggplot2 coord_cartesian
#' @importFrom ggplot2 element_text
NULL
#' Plot FastQC Results
#' @description Plot FastQC data
#' @param qc An object of class qc_read or a path to the sample zipped fastqc result file.
#' @param modules Character vector containing the names of fastqc modules for
#'   which you want to import the data. Default is all. Allowed values include
#'   one or the combination of:
#'   \itemize{
#'   \item "Summary",
#'    \item "Basic Statistics",
#'    \item "Per base sequence quality",
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
#' @return Returns a list of ggplots containing the plot for specified modules..
#' @examples
#' # Demo file
#' qc.file <- system.file("fastqc_results", "S1_fastqc.zip",  package = "fastqcr")
#' qc.file
#' # Read all modules
#' qc <- qc_read(qc.file)
#'
#' # Plot per sequence GC content
#' qc_plot(qc, "Per sequence GC content")
#'
#' # Per base sequence quality
#' qc_plot(qc, "Per base sequence quality")
#'
#' # Per sequence quality scores
#' qc_plot(qc, "Per sequence quality scores")
#'
#' # Per base sequence content
#' qc_plot(qc, "Per base sequence content")
#'
#' # Sequence duplication levels
#' qc_plot(qc, "Sequence duplication levels")
#'
#'
#' @export
qc_plot <- function(qc, modules = "all"){

  if(inherits(qc, "character"))
    qc <- qc_read(qc)
  if(!inherits(qc, "qc_read"))
    stop("data should be an object of class qc_read")

  . <- NULL
  modules <- .valid_fastqc_modules(modules) %>%
    tolower() %>%
    gsub(" ", "_", .)

   res <- lapply(modules,
                function(module, qc){
                  plot.func <- .plot_funct(module)
                  status <- .get_status(qc, gsub("_", " ", module))
                  plot.func(qc, status = status)
                },
                qc
  )

  names(res) <- modules
  if(length(res) == 1) res[[1]]
  else res
}

#' @param x an object of class qctable.
#' @param ... other arguments.
#' @method print qctable
#' @rdname qc_plot
#' @export
print.qctable <- function(x, ...){
  grid::grid.newpage()
  gridExtra::grid.table(x, rows = NULL)
}


# Extrcat the plotting function according to the module
.plot_funct <- function(module){

  switch(module,
         per_sequence_gc_content = .plot_gc_content,
         per_base_sequence_quality = .plot_base_quality,
         per_sequence_quality_scores = .plot_sequence_quality,
         per_base_sequence_content = .plot_sequence_content,
         sequence_duplication_levels = .plot_duplication_levels,
         basic_statistics = .plot_basic_stat,
         sequence_length_distribution = .plot_seq_length_distribution,
         summary = .plot_summary,
         per_base_n_content = .plot_N_content,
         overrepresented_sequences = .plot_overrepresented_sequences,
         adapter_content = .plot_adapter_content,
         kmer_content = .plot_kmer_content,
         function(x){NULL}
)
}


# Basic statistics
.plot_basic_stat <- function(qc, ggtheme = theme_minimal(), ...){
  if(!("basic_statistics" %in% names(qc)))
    return(NULL)
  d <- qc$basic_statistics
  d <- structure(d, class = c("qctable", class(d)))
  d
}

# Plot summary
.plot_summary <- function(qc, ggtheme = theme_minimal(), ...){
  if(!("summary" %in% names(qc)))
    return(NULL)
  d <- qc$summary
  d <- structure(d, class = c("qctable", class(d)))
  d
}

# Per sequence GC content
.plot_gc_content <- function(qc, ggtheme = theme_minimal(), status = NULL, ...){
  .names <- names(qc)
  if(!("per_sequence_gc_content" %in% .names))
    return(NULL)

  d <- qc$per_sequence_gc_content
  if(nrow(d) == 0) return(NULL)
  colnames(d) <- make.names(colnames(d))
  ggplot(d, aes_string(x = "GC.Content", y = "Count"))+
    geom_line() +
    labs(title = "Per sequence GC content", x = "Mean GC Content (%)",
         caption = paste0("Status: ", status))+
    theme_minimal()+
    theme(plot.caption = element_text(color = switch(status, PASS = "#00AFBB", WARN = "#E7B800", FAIL = "#FC4E07")))
}


# Per base N content
.plot_N_content <- function(qc, ggtheme = theme_minimal(), status = NULL, ...){
  if(!("per_base_n_content" %in% names(qc)))
    return(NULL)

  . <- NULL

  d <- qc$per_base_n_content
  if(nrow(d) == 0) return(NULL)
  colnames(d) <- make.names(colnames(d))
  d$Base <- factor(d$Base, levels = d$Base)

  # Select some breaks
  nlev <- nlevels(d$Base)
  breaks <- scales::extended_breaks()(1:nlev)[-1] %>% # index
    c(1, ., nlev) %>% # Add the minimum & the max
    d$Base[.] %>% # Values
    as.vector()


  ggplot(d, aes_string(x = "Base", y = "N.Count", group = 1))+
    geom_line() +
    scale_x_discrete(breaks = breaks)+
    coord_cartesian(ylim = c(0, 100))+
    labs(title = "Per base N content", x = "Position in read (bp)",
         y = "Frequency (%)",
         subtitle = "N content across all bases",
         caption = paste0("Status: ", status))+
    theme_minimal()+
    theme(plot.caption = element_text(color = switch(status, PASS = "#00AFBB", WARN = "#E7B800", FAIL = "#FC4E07")))
}


# Sequence Length Distribution
.plot_seq_length_distribution <- function(qc, ggtheme = theme_minimal(), status = NULL, ...){
  if(!("sequence_length_distribution" %in% names(qc)))
    return(NULL)

  d <- qc$sequence_length_distribution
  if(nrow(d) == 0) return(NULL)

  ggplot(d, aes_string(x = "Length", y = "Count"))+
    geom_line() +
    labs(title = "Sequence length distribution", x = "Sequence Length (pb)",
         y = "Count",
         subtitle = "Distribution of sequence lengths over all sequences",
         caption = paste0("Status: ", status))+
    theme_minimal()+
    theme(plot.caption = element_text(color = switch(status, PASS = "#00AFBB", WARN = "#E7B800", FAIL = "#FC4E07")))
}

# Per base sequence quality
.plot_base_quality <- function(qc, ggtheme = theme_minimal(), status = NULL, ...){

  .names <- names(qc)
  if(!("per_base_sequence_quality" %in% .names))
    return(NULL)
  . <- NULL

  d <- qc$per_base_sequence_quality
  if(nrow(d) == 0) return(NULL)
  
  colnames(d) <- make.names(colnames(d))
  d$Base <- factor(d$Base, levels = d$Base)
  # Select some breaks
  nlev <- nlevels(d$Base)
  breaks <- scales::extended_breaks()(1:nlev)[-1] %>% # index
    c(1, ., nlev) %>% # Add the minimum & the max
    d$Base[.] %>% # Values
    as.vector()


  ggplot()+
    geom_line(data = d, aes_string(x = "Base", y = "Median", group = 1)) +
    expand_limits(x = 0, y = 0)+
    geom_rect(aes(xmin = 0, ymin = 0, ymax = 20, xmax = Inf),
              fill = "red", alpha = 0.2)+
    geom_rect(aes(xmin = 0, ymin = 20, ymax = 28, xmax = Inf),
              fill = "yellow", alpha = 0.2)+
    geom_rect(aes(xmin = 0, ymin = 28, ymax = Inf, xmax = Inf),
              fill = "#00AFBB", alpha = 0.2)+
    scale_x_discrete(breaks = breaks)+
    labs(title = "Per base sequence quality", x = "Position in read (pb)",
         y = "Median quality scores",
         subtitle = "Red: low quality zone",
         caption = paste0("Status: ", status))+
    theme_minimal()+
    theme(plot.caption = element_text(color = switch(status, PASS = "#00AFBB", WARN = "#E7B800", FAIL = "#FC4E07")))
}

# Per sequence quality scores
.plot_sequence_quality <- function(qc, ggtheme = theme_minimal(), status = NULL, ...){
  .names <- names(qc)
  if(!("per_sequence_quality_scores" %in% .names))
    return(NULL)

  d <- qc$per_sequence_quality_scores
  if(nrow(d) == 0) return(NULL)
  
  ggplot(d, aes_string(x = "Quality", y = "Count"))+
    geom_line() +
    labs(title = "Per sequence quality scores",
         subtitle = "Quality score distribution over all sequences",
         x = "Mean Sequence Quality (Phred Score)",
         caption = paste0("Status: ", status))+
    theme_minimal()+
    theme(plot.caption = element_text(color = switch(status, PASS = "#00AFBB", WARN = "#E7B800", FAIL = "#FC4E07")))
}

# Per base sequence content
.plot_sequence_content <- function(qc, ggtheme = theme_minimal(), status = NULL, ...){
  .names <- names(qc)
  if(!("per_base_sequence_content" %in% .names))
    return(NULL)

  . <- NULL

  Base <- NULL
  d <- qc$per_base_sequence_content
  if(nrow(d) == 0) return(NULL)
  
  d$Base <- factor(d$Base, levels = d$Base)
  d <- d %>%
    tidyr::gather(key = "base_name", value = "Count", -Base)
  

  # Select some breaks
  nlev <- nlevels(d$Base)
  breaks <- scales::extended_breaks()(1:nlev)[-1] %>% # index
    c(1, ., nlev) %>% # Add the minimum & the max
    d$Base[.] %>% # Values
    as.vector()


  ggplot(d, aes_string(x = "Base", y = "Count", group = "base_name", color = "base_name"))+
    geom_line() +
    scale_x_discrete(breaks = breaks)+
    labs(title = "Per base sequence content",
         subtitle = "Sequence content across all bases",
         caption = paste0("Status: ", status),
         x = "Position in read (pb)", y = "Nucleotide frequency (%)",
         color = "Nucleotide")+
    coord_cartesian(ylim = c(0, 100))+
    theme_minimal() +
    theme(legend.position = c(0.5, 0.7), legend.direction = "horizontal")+
    theme(plot.caption = element_text(color = switch(status, PASS = "#00AFBB", WARN = "#E7B800", FAIL = "#FC4E07")))
}


# Sequence Duplication Levels
.plot_duplication_levels <- function(qc, ggtheme = theme_minimal(), status = NULL, ...){
  .names <- names(qc)
  if(!("per_base_sequence_content" %in% .names))
    return(NULL)

  . <- NULL
  Duplication.Level <- NULL
  d <- qc$sequence_duplication_levels
  if(nrow(d) == 0) return(NULL)
  colnames(d) <- make.names(colnames(d))
  d$Duplication.Level <- factor(d$Duplication.Level, levels = d$Duplication.Level)
  d <- d %>%
    tidyr::gather(key = "Dup", value = "pct", -Duplication.Level)

  # Select some breaks
  nlev <- nlevels(d$Duplication.Level)
  breaks <- scales::extended_breaks()(1:nlev)[-1] %>% # index
    c(1, ., nlev) %>% # Add the minimum & the max
    d$Duplication.Level[.] %>% # Values
    as.vector()


  ggplot(d, aes_string(x = "Duplication.Level", y = "pct", group = "Dup", color = "Dup"))+
    geom_line() +
    # scale_x_discrete(breaks = breaks)+
    labs(title = "Sequence Duplication Levels",
         subtitle = paste0("Percentage of distinct reads: ", qc$total_deduplicated_percentage, "%"),
         x = "Sequence Duplication Level", y = "Percentage",
         caption = paste0("Status: ", status),
         color = "")+
    theme_minimal() +
    theme(legend.position = c(0.5, 0.7))+
    theme(plot.caption = element_text(color = switch(status, PASS = "#00AFBB", WARN = "#E7B800", FAIL = "#FC4E07")))
}



# Overrepresented sequences
.plot_overrepresented_sequences <- function(qc, status = NULL, ...){
  if(!("overrepresented_sequences" %in% names(qc)))
    return(NULL)

  d <-  qc$overrepresented_sequences

  if(nrow(d) == 0 )
    ggplot(d)+
    labs(title = "Overrepresented sequences")+
    ggplot2::annotate("text", x = 0.5, y = 0.5, label = "No overrepresented sequences",
                      size = 5, color = "steelblue")+
    ggplot2::theme_void()+
    theme(plot.caption = element_text(color = switch(status, PASS = "#00AFBB", WARN = "#E7B800", FAIL = "#FC4E07")))

  else {
    d <- qc$overrepresented_sequences
    # d <- structure(d, class = c("qctable", class(d)))
    d
  }

}

# Adapter Content
.plot_adapter_content <- function(qc, status = NULL, ...){
  if(!("adapter_content" %in% names(qc)))
    return(NULL)

  Position <- NULL

  d <-  qc$adapter_content
  colnames(d) <- make.names(colnames(d))
  d <- d %>%
    tidyr::gather(key = "adapter", value = "value", -Position)
  ggplot(d, aes_string(x = "Position", y = "value", group = "adapter", color = "adapter"))+
    geom_line() +
    labs(title = "Adapter content",
         caption = paste0("Status: ", status),
         x = "Position in read (pb)", y = "% Adapter",
         color = "")+
    theme_minimal() +
    coord_cartesian(ylim = c(0, 100))+
    theme(legend.position = c(0.5, 0.8))+
    theme(plot.caption = element_text(color = switch(status, PASS = "#00AFBB", WARN = "#E7B800", FAIL = "#FC4E07")))
}

# Overrepresented sequences
.plot_kmer_content <- function(qc, status = NULL, ...){
  if(!("kmer_content" %in% names(qc)))
    return(NULL)

  d <-  qc$kmer_content

  if(nrow(d) == 0 )
    ggplot(d)+
    labs(title = "Kmer content")+
    ggplot2::annotate("text", x = 0.5, y = 0.5, label = "No overrepresented kmers",
                      size = 5, color = "steelblue")+
    ggplot2::theme_void()+
    theme(plot.caption = element_text(color = switch(status, PASS = "#00AFBB", WARN = "#E7B800", FAIL = "#FC4E07")))

  else {
    # d <- structure(d, class = c("qctable", class(d)))
    qc$kmer_content
  }

}


.plot_tile_seq_quality <- function(qc, status = NULL, ...){
  if(!("per_tile_sequence_quality" %in% names(qc)))
    return(NULL)

  d <-  qc$per_tile_sequence_quality
  if(nrow(d) == 0) return(NULL)
  
  d$Tile <- as.character(d$Tile)
  d$Base <- factor(d$Base, levels = d$Base)

  ggplot(d, aes_string(x = "Base", y = "Tile", fill = "Mean"))+
    ggplot2::geom_tile() +
    labs(title = "Per tile sequence quality",
         subtitle = "Quality per tile",
         caption = paste0("Status: ", status),
         x = "Position in read (pb)")+
    theme_minimal()
}


# Ge module status
.get_status <- function(qc, .module){
  module <- . <- NULL
  dplyr::filter(qc$summary, tolower(module) == .module) %>%
    .$status
}


