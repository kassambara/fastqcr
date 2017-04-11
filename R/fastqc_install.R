#' @include utilities.R
NULL
#' Install FastQC Tool
#' @description Install the FastQC Tool. To be used only on Unix system.
#' @param url url to download the latest version. If missing, the function will
#'   try to install the latest version from
#'   \href{http://www.bioinformatics.babraham.ac.uk/projects/download.html#fastqc}{http://www.bioinformatics.babraham.ac.uk/projects/download.html#fastqc}.
#' @param dest.dir destination directory to install the tool.
#' @export
fastqc_install <- function(url, dest.dir = "~/bin"){

  if(missing(url)){
    . <- NULL
    # Get the latest version of fastq
    download_page <- xml2::read_html("http://www.bioinformatics.babraham.ac.uk/projects/download.html")
    link_hrefs <- download_page %>%
      rvest::html_nodes("a") %>%
      rvest::html_attr("href")
    fastqc_href <- grep("fastqc/fastqc.*.zip",
                        link_hrefs, perl = TRUE) %>%
      link_hrefs[.] %>% .[1]
    url <- paste0("http://www.bioinformatics.babraham.ac.uk/projects/",
                 fastqc_href)
  }
  .remove(file.path(dest.dir, "FastQC")) # remove old version if exists
  dest.file <- file.path(dest.dir, basename(url))
  .check_if_unix()
  .create_dir(dest.dir)
  utils::download.file(url, destfile = dest.file)
  utils::unzip(dest.file, exdir = dest.dir)
  .remove(dest.file)
  Sys.chmod(file.path(dest.dir, "FastQC/fastqc"), mode = "0755", use_umask = TRUE)
  .add_path_to_profile("export PATH=$PATH:~/bin/FastQC\n")
}

