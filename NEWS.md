# bcbioSmallRna 0.0.1

## Fix
* Compatible with last isomiRs version
* Fix annotation names for inter-genic clusters
* Add plots to the template and remove it from the function
* Fix bcbioSmallSizeDist to avoid duplication of columns when getting adapter information

## Feature
* Re-organize cluster figure in QC report
* Use multiqc file to read metrics
* Add sequence matrix for cluster analysis
* Plot size disribution by small RNA type
* Change to use varianzeStabilization from DESeq2 to normalize counts,
  as consequence, name of slot of normalized count changed to `log`
* Load final folder using project folder path instead
* Feature: Improve cluster annotation