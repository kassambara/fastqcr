#' @include utilities.R qc_aggregate.R
NULL
#' Inspect Problems in Aggregated FastQC Reports
#' 
#' @description Inspect problems in aggregated FastQC reports.
#' @param object an object of class qc_aggregate.
#' @return
#' \itemize{
#'    \item \strong{qc_problems(), qc_fails(), qc_warns()}: returns a tibble (data frame) containing samples
#'    that had one or more modules with failure or warning.
#'    The format and the interpretation of the results depend on the argument 'element',
#'    which value is one of c("sample", "module").
#'     \itemize{
#'     \item \strong{If element = "sample" (default)}, results are samples with failed and/or warned modules. 
#'     The results contain the following columns: sample (sample names),
#'     nb_problems (the number of modules with problems), module (the name of modules with problems).
#'     \item \strong{If element = "module"}, results are modules that failed and/or warned in the most samples. 
#'     The results contain the following columns:
#'     module (the name of module with problems), nb_problems (the number of samples with problems),
#'     sample (the name of samples with problems)
#'     }
#'     
#'   }
#' @examples
#' # Demo QC dir
#' qc.dir <- system.file("fastqc_results", package = "fastqcr")
#' qc.dir
#' # List of files in the directory
#' list.files(qc.dir)
#'
#' # Aggregate the report
#' qc <- qc_aggregate(qc.dir, progressbar = FALSE)
#' 
#' # Display samples with failed modules
#' qc_fails(qc)
#' qc_fails(qc, compact = FALSE)
#' 
#' # Display samples with warned modules
#' qc_warns(qc)
#' 
#' # Module failed in the most samples
#' qc_fails(qc, "module")
#' qc_fails(qc, "module", compact = FALSE)
#' 
#' # Specify a module of interest
#' qc_problems(qc, "module",  name = "Per sequence GC content")
#' 
#' @describeIn qc_problems Displays which samples had one or more failed modules. Use
#'   qc_fails(qc, "module") to see which modules failed in the most samples.
#' @export
qc_fails <- function(object, element = c("sample", "module"), compact = TRUE){
  .check_object(object)
  element <- match.arg(element)
  qc_problems (object, element = element, status = "FAIL", compact = compact)
}

#' @describeIn qc_problems Displays which samples had one or more warned modules. Use
#'   qc_warns(qc, "module") to see which modules warned in the most samples.
#' @export
qc_warns <- function(object, element = c("sample", "module"), compact = TRUE){
  .check_object(object)
  element <- match.arg(element)
  qc_problems (object, element = element, status = "WARN", compact = compact)
}


#'@describeIn qc_problems Union of \code{qc_fails()} and \code{qc_warns()}. 
#'  Display which samples or modules that failed or warned.
#'@param element character vector specifying which element to check for 
#'  inspecting problems. Allowed values are one of c("sample", "module"). 
#'  Default is "sample". \itemize{ \item If "sample", shows samples with more 
#'  failed and/or warned modules \item If "module", shows moduled that failed 
#'  and/or warned in the most samples }
#'@param name character vector containing the names of modules and/or samples of
#'  interest. See \link{qc_read} for valid module names. If name specified, a 
#'  stretched output format is returned by default unless you explicitly indicate
#'  compact = TRUE.
#'@param status character vector specifying the module status. Allowed values 
#'  includes one or the combination of c("FAIL", "WARN"). If status = "FAIL", 
#'  only modules with failed status are returned.
#'@param compact logical value. If TRUE, returns a compact output format; 
#'  otherwise, returns a stretched format.
#'@export
qc_problems <- function(object,
                        element = c("sample", "module"),
                        name = NULL,
                        status = c("FAIL", "WARN"),
                        compact = TRUE)
  {
  
  .check_object(object)
  element <- match.arg(element)
  not_element <- base::setdiff(c("sample", "module"), element)
  
  if(!all(status %in% c("FAIL", "WARN")))
    stop("status should be one of c('FAIL', 'WARN')")
  
  sample  <- nb_problems <- module <- NULL
  status. <- status
  problems <- object %>%
    dplyr::filter(status %in% status.) %>%
    dplyr::select(sample, module, status)
  
  if(nrow(problems) == 0){
    message("There is no problem. All samples pass the QC tests.")
    return(problems)
  }
  
  # Selected sample or module names
  if(!is.null(name)){
    all.valid.names <- c(problems$sample, problems$module) %>%
      unique()
    # partial matching of names
    name <- grep(pattern= paste(name, collapse = "|"), all.valid.names,
                    ignore.case = TRUE, value = TRUE) %>%
      unique()
    if(length(name) == 0) stop("Incorect names provided.")
    # Filtering names
    problems <- problems %>%
      dplyr::filter(sample %in% name | module %in% name)
    
    if(missing(compact)) compact <- FALSE
  }
  
  nb_problems <- problems %>%
    dplyr::group_by(!!!syms(element)) %>%
    dplyr::summarise(nb_problems = n()) %>%
    dplyr::arrange(desc(nb_problems))
  
  # Aggregating by unique sample and concatenating related values into a string
  module <- sample <- NULL
  if(element == "sample") .formula <- module~sample
  else
    .formula <- sample~module
  modules_with_problem <- stats::aggregate(.formula, data = problems,
                                           paste, collapse = ", ")
  if(compact) 
    left_join(nb_problems, modules_with_problem, by = element)
  else
    left_join(problems, nb_problems, by = element) %>%
    dplyr::arrange(desc(nb_problems), !!!syms(c(element,  "status"))) %>%
    dplyr::select(element, dplyr::all_of(c("nb_problems", not_element, "status")))
}

