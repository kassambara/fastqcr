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
#' @importFrom ggplot2 facet_wrap
NULL

#' Plot FastQC Results of multiple samples
#' 
#' @description Plot FastQC data of multiple samples 
#' 
#' @param qc An object of class qc_read_collection or a path to the sample zipped fastqc result files.
#' @inheritParams qc_plot
#' 
#' @author Mahmoud Ahmed, \email{mahmoud.s.fahmy@students.kasralainy.edu.eg}
#'
#' @return Returns a list of ggplots containing the plot for specified modules..
#' @examples
# extract paths to the demo files
#' qc.dir <- system.file("fastqc_results", package = "fastqcr")
#' qc.files <- list.files(qc.dir, full.names = TRUE)[1:2]
#' nb_samples <- length(qc.files)
#' 
#' # read specific modules in all files
#' # To read all modules, specify: modules = "all"
#' modules <- c(
#'   "Per sequence GC content",
#'   "Per base sequence quality",
#'  "Per sequence quality scores"
#' )
#' qc <- qc_read_collection(qc.files, sample_names = paste('S', 1:nb_samples, sep = ''),
#'        modules = modules)
#'
#' # Plot per sequence GC content
#' qc_plot_collection(qc, "Per sequence GC content")
#'
#' # Per base sequence quality
#' qc_plot_collection(qc, "Per base sequence quality")
#' 
#' # Per sequence quality scores
#' qc_plot_collection(qc, "Per sequence quality scores")
#'
#'
#' @export
qc_plot_collection <- function(qc, modules = "all"){
  
  if(inherits(qc, "character"))
    qc <- qc_read(qc)
  if(!inherits(qc, "qc_read_collection"))
    stop("data should be an object of class qc_read_collection")
  
  . <- NULL
  modules <- .valid_fastqc_modules(modules) %>%
    tolower() %>%
    gsub(" ", "_", .)
  
  res <- lapply(modules,
                function(module, qc){
                  plot.func.collection <- .plot_funct_collection(module)
                  plot.func.collection(qc)
                },
                qc
  )
  
  names(res) <- modules
  if(length(res) == 1) res[[1]]
  else res
}

# Extrcat the plotting function according to the module
.plot_funct_collection <- function(module){
  
  switch(module,
         per_sequence_gc_content = .plot_gc_content_collection,
         per_base_sequence_quality = .plot_base_quality_collection,
         per_sequence_quality_scores = .plot_sequence_quality_collection,
         per_base_sequence_content = .plot_sequence_content_collection,
         sequence_duplication_levels = .plot_duplication_levels_collection,
         basic_statistics = .plot_basic_stat,
         sequence_length_distribution = .plot_seq_length_distribution_collection,
         summary = .plot_summary,
         per_base_n_content = .plot_N_content_collection,
         adapter_content = .plot_adapter_content_collection,
         function(x){NULL}
  )
}

# Per sequence GC content
.plot_gc_content_collection <- function(qc, ggtheme = theme_minimal(), ...){
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


# Per base N content
.plot_N_content_collection <- function(qc, ggtheme = theme_minimal(), ...){
  if(!("per_base_n_content" %in% names(qc)))
    return(NULL)
  
  . <- NULL
  
  d <- qc$per_base_n_content
  if(nrow(d) == 0) return(NULL)
  colnames(d) <- make.names(colnames(d))
  d$Base <- factor(d$Base, levels = unique(d$Base))

  # Select some breaks
  nlev <- nlevels(d$Base)
  breaks <- scales::extended_breaks()(1:nlev)[-1] %>% # index
    c(1, ., nlev) %>% # Add the minimum & the max
    d$Base[.] %>% # Values
    as.vector()
  
  
  ggplot(d, aes_string(x = "Base", y = "N.Count", color = 'sample', group = 'sample')) +
    geom_line() +
    scale_x_discrete(breaks = breaks)+
    coord_cartesian(ylim = c(0, 100))+
    labs(title = "Per base N content", x = "Position in read (bp)",
         y = "Frequency (%)",
         subtitle = "N content across all bases")+
    theme_minimal()
}


# Sequence Length Distribution
.plot_seq_length_distribution_collection <- function(qc, ggtheme = theme_minimal(), ...){
  if(!("sequence_length_distribution" %in% names(qc)))
    return(NULL)
  
  d <- qc$sequence_length_distribution
  if(nrow(d) == 0) return(NULL)
  
  ggplot(d, aes_string(x = "Length", y = "Count", color = 'sample'))+
    geom_line() +
    labs(title = "Sequence length distribution", x = "Sequence Length (pb)",
         y = "Count",
         subtitle = "Distribution of sequence lengths over all sequences")+
    theme_minimal()
  }

# Per base sequence quality
.plot_base_quality_collection <- function(qc, ggtheme = theme_minimal(), ...){
  
  .names <- names(qc)
  if(!("per_base_sequence_quality" %in% .names))
    return(NULL)
  . <- NULL
  
  d <- qc$per_base_sequence_quality
  if(nrow(d) == 0) return(NULL)
  
  colnames(d) <- make.names(colnames(d))
  d$Base <- factor(d$Base, levels = unique(d$Base))
  # Select some breaks
  nlev <- nlevels(d$Base)
  breaks <- scales::extended_breaks()(1:nlev)[-1] %>% # index
    c(1, ., nlev) %>% # Add the minimum & the max
    d$Base[.] %>% # Values
    as.vector()
  
  
  ggplot()+
    geom_line(data = d, aes_string(x = "Base", y = "Median", group = 'sample', color = 'sample')) +
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
         subtitle = "Red: low quality zone")+
    theme_minimal()
}

# Per sequence quality scores
.plot_sequence_quality_collection <- function(qc, ggtheme = theme_minimal(), status = NULL, ...){
  .names <- names(qc)
  if(!("per_sequence_quality_scores" %in% .names))
    return(NULL)
  
  d <- qc$per_sequence_quality_scores
  if(nrow(d) == 0) return(NULL)
  colnames(d) <- c("sample", "quality", "count")
  ggplot(d, aes_string(x = "quality", y = "count", color = 'sample'))+
    geom_line() +
    labs(title = "Per sequence quality scores",
         subtitle = "Quality score distribution over all sequences",
         x = "Mean Sequence Quality (Phred Score)", y = "Count")+
    theme_minimal()
}

# Per base sequence content
.plot_sequence_content_collection <- function(qc, ggtheme = theme_minimal(), ...){
  .names <- names(qc)
  if(!("per_base_sequence_content" %in% .names))
    return(NULL)
  
  . <- NULL
  
  Base <- NULL
  d <- qc$per_base_sequence_content
  if(nrow(d) == 0) return(NULL)
  
  d$Base <- factor(d$Base, levels = unique(d$Base))
  d <- d %>%
    tidyr::gather(key = "base_name", value = "Count", -Base, -sample)
  
  
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
         x = "Position in read (pb)", y = "Nucleotide frequency (%)",
         color = "Nucleotide")+
    coord_cartesian(ylim = c(0, 100))+
    facet_wrap(~sample, ncol = 1, strip.position = 'right') +
    theme_minimal() +
    theme(legend.position = 'top', legend.direction = "horizontal")
}


# Sequence Duplication Levels
.plot_duplication_levels_collection <- function(qc, ggtheme = theme_minimal(), ...){
  .names <- names(qc)
  if(!("per_base_sequence_content" %in% .names))
    return(NULL)
  
  . <- NULL
  Duplication.Level <- NULL
  d <- qc$sequence_duplication_levels
  if(nrow(d) == 0) return(NULL)
  colnames(d) <- make.names(colnames(d))
  d$Duplication.Level <- factor(d$Duplication.Level, levels = unique(d$Duplication.Level))
  d <- d %>%
    tidyr::gather(key = "Dup", value = "pct", -Duplication.Level, -sample)
  
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
         x = "Sequence Duplication Level", y = "Percentage",
         color = "")+
    facet_wrap(~sample, ncol = 1, strip.position = 'right') +
    theme_minimal() +
    theme(legend.position = 'top')
}


# Adapter Content
.plot_adapter_content_collection <- function(qc, ggtheme = theme_minimal(), ...){
  if(!("adapter_content" %in% names(qc)))
    return(NULL)
  
  Position <- NULL
  
  d <-  qc$adapter_content
  colnames(d) <- make.names(colnames(d))
  d <- d %>%
    tidyr::gather(key = "adapter", value = "value", -Position, -sample)
  ggplot(d, aes_string(x = "Position", y = "value", group = "adapter", color = "adapter"))+
    geom_line() +
    labs(title = "Adapter content",
         x = "Position in read (pb)", y = "% Adapter",
         color = "")+
    coord_cartesian(ylim = c(0, 100))+
    facet_wrap(~sample, ncol = 1, strip.position = 'right') +
    theme_minimal() +
    theme(legend.position = 'top')
}

# Per tile sequence quality
.plot_tile_seq_quality_collection <- function(qc, ...){
  if(!("per_tile_sequence_quality" %in% names(qc)))
    return(NULL)
  
  d <-  qc$per_tile_sequence_quality
  if(nrow(d) == 0) return(NULL)
  
  d$Tile <- as.character(d$Tile)
  d$Base <- factor(d$Base, levels = unique(d$Base))
  
  ggplot(d, aes_string(x = "Base", y = "Tile", fill = "Mean"))+
    ggplot2::geom_tile() +
    labs(title = "Per tile sequence quality",
         subtitle = "Quality per tile",
         x = "Position in read (pb)") +
    theme_minimal() +
    theme(legend.position = 'top', legend.direction = 'horizontal') +
    facet_wrap(~sample, ncol = 1, strip.position = 'right')
}
