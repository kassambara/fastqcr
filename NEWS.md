# fastqcr 0.1.3

   
## Minor changes

- Using `select()` in place of the deprecated `select_()` function in `qc_aggregate()` and `qc_problems()` (#24)
- Using `arrange()` and `group_by()` in place of the deprecated `arrange_()` and `group_by()_` functions in `qc_problems()`
- Changing http to https for urls concerning fastc installation and documentation
- `qc_read_collection()` and `qc_plot_collection()` examples reduced to less than 5 seconds 

## Bug fixes

- Remove extra args (`fill`) in `left_join()` from `qc_aggregate()` function (#23)

# fastqcr 0.1.2

## Bug fixes
   
- Revert "Fix for readr 1.2.0": readr 1.3.0 changes the skip line behavior to match that of readr 1.1.1,
the change in 1.2.0 was determined to be too disruptive (@jimhester, [#11](https://github.com/kassambara/fastqcr/pull/11)).

# fastqcr 0.1.1

## New features

New functions added to read and plot a collection of samples together:  
   
- `qc_read_collection()` (@MahShaaban , [#4](https://github.com/kassambara/fastqcr/pull/4))
- `qc_plot_collection()` (@MahShaaban , [#4](https://github.com/kassambara/fastqcr/pull/5))

When possible, the data from multiple samples are overlayed on a single graph and otherwise on multiple facets (when there is more than one line in a one sample plot). As with plotting the single file modules, the function `qc_plot_collection()` dispatches on the appropriate class `qc_read_collection()` and calls the internals corresponding to the input of the argument modules.
   
   
## Bug fixes
   
- Fix for readr 1.2.0 (@jimhester, [#7](https://github.com/kassambara/fastqcr/pull/7))


## Minor changes
  
- New argument `fastqc.path` added to the function `fastqc()`.

## Bug fixes


# fastqcr 0.1.0
    
    
## Bug fixes
   
- Now, `qc_report()`  handles better relative paths to FastQC zipfiles ([@ACharbonneau, #1](https://github.com/kassambara/fastqcr/issues/1))
    
## New features
   
   
- **fastqc_install**(): Install the latest version of FastQC tool on Unix systems (MAC OSX and Linux)
   
- **fastqc**(): Run the FastQC tool from R.
  
- **qc <- qc_aggregate**(): Aggregate multiple FastQC reports into a data frame.
   
- **summary**(qc): Generates a summary of qc_aggregate. 
  
- **qc_stats**(qc): General statistics of FastQC reports.
    
- **qc_fails**(qc): Displays samples or modules that failed.
   
- **qc_warns**(qc): Displays samples or modules that warned.
    
- **qc_problems**(qc, "sample"): Union of **qc_fails**() and **qc_warns**(). Display which samples or modules that failed or warned.
   
- **qc\_read**(): Read FastQC data into R.
   
- **qc\_plot**(qc): Plot FastQC data
  
- **qc\_report**(): Create an HTML file containing FastQC reports of one or multiple files. Inputs can be either a directory containing multiple FastQC reports or a single sample FastQC report.
   
- **qc\_unzip**(): Unzip all zipped files in the qc.dir directory.
   
   

