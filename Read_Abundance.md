# Metagenomics Read Abundance Workflow

## Step 1: Consolidate Kraken Reports

You start with your trimmed and quality controlled reads. These need to be classified, I’ve used Kraken2 for short reads. (I believe that it should still work for long reads though, but double check). You will get a separate `.tab` report for each of your samples.
Create a file/digital sticky note with all of the file’s names: ls > list_samples.tab. You will need to run the python script kraken2_long_to_wide.py from your computer’s terminal in the same directory as you’ve kept your separate kraken reports: 

```
python kraken2_long_to_wide.py -i [list of your file names, separated by tab/space] -o kraken_analytic_matrix.csv
```

This will generate 2 files, `kraken_unclassifieds.csv` and `kraken_analytic_matrix.csv`.

## Step 2: Reformat Matrix

Then, you will get an output matrix. Should look something like:
 
You are going to have to open the kraken_analytic_matrix.csv file in excel and move the headers to align with their read counts, leaving A1 cell blank.

Then, insert 7 columns to the left of the A column. You will then select the entire A column and separate the column by a deliminater.
 
   
 
Once you hit finish you’ll get:
 

Add the headers Domain, Kingdom, Phylum, Class, Order, Family, Genus, Species in the empty headers in row 1.

