#' @importFrom magrittr %>%
#' @import dplyr

# Create a directory
.create_dir <- function(path){
  if(!dir.exists(path))
    dir.create(path, showWarnings = FALSE, recursive = TRUE)
}

# Check if unix system
.check_if_unix <- function(){
  os <- .Platform$OS.type
  if(!(os == "unix"))
    stop("Unix system (MAC OSX or Linux) required.")
}

# Remove a file or a directory
.remove <- function(x){
  unlink(x, recursive = TRUE)
}

# Add a program path to profile
.add_path_to_profile <- function(.path){
  .profile = ""
  if(file.exists("~/.profile")) .profile <- readLines("~/.profile")
  if(!(.path %in% .profile)){
    sink("~/.profile")
    cat(.path)
    sink()
  }

}

# Check if a variable is empty
.is_empty <- function(x){
  length(x) == 0
}

# Check and returns valid fastqc modules
.valid_fastqc_modules <- function(modules = "all"){
  
  allowed.modules <- c("Summary",
                       "Basic Statistics",
                       "Per base sequence quality",
                       "Per tile sequence quality",
                       "Per sequence quality scores",
                       "Per base sequence content",
                       "Per sequence GC content",
                       "Per base N content",
                       "Sequence Length Distribution",
                       "Sequence Duplication Levels",
                       "Overrepresented sequences",
                       "Adapter Content",
                       "Kmer Content")
  
  # Modules
  if( "all" %in% modules)
    modules <- allowed.modules
  else{
    # partial matching of module names
    modules <- grep(pattern= paste(modules, collapse = "|"), allowed.modules,
                    ignore.case = TRUE, value = TRUE) %>%
      unique()
    if(length(modules) == 0) {
      stop("Incorect module names provided. Allowed values include: \n\n",
           paste(allowed.modules, collapse = "\n- "))
    }
  }
  
  modules
}



# File and directory
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Check if path is directory
.is_dir <- function(path){
  dir.exists(path)
}

# Check if file
.is_file <- function(path){
  file.exists(path)
}

# Check if a path exists. Pah can be file or directory
.path.exists <- function(path){
  .is_dir(path) | .is_file(path)
}

# File extension
.file_ext <- function(x){
  pos <- regexpr("\\.([[:alnum:]]+)$", x)
 ifelse(pos > -1L, substring(x, pos + 1L), "")
}

# read_file for zipped qc
.read_file_zip <- function(.zip, filename){
  . <- NULL
  # Folder name when unzipped
  .zip_folder <- basename(.zip) %>%
    gsub(".zip", "", .)
  filepath <- file.path(.zip_folder, filename)
  readr::read_file(unz(.zip, filepath))
}



# Open file
# path = absolute path
.open_file <- function(path=NULL){

    OS = .Platform$OS.type

    if(OS == "unix"){
      if(Sys.info()["sysname"] == "Linux") OS = "linux"
      else OS = "mac"
    }

    switch(OS,
           windows = shell.exec(path),
           mac = system(paste0("open ", path)),
           linux = {
             if(interactive()) system(paste0("xdg-open ", path))
             else cat("File path: ", path, "\n")
             }
           )
}

.preview_site <- function (path) {
  utils::browseURL(path)
}


