# fastqcr 0.1.0
    
    
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
   
   

