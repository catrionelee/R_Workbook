# Metagenomics Read Abundance Workflow

Follow along with the accompanying [R Script](https://github.com/catrionelee/R_Workbook/blob/main/metagenomics_analysis_script_CL.R).

## Step 1: Consolidate Kraken Reports

You start with your trimmed and quality controlled reads. These need to be classified, I’ve used Kraken2 for short reads. (I believe that it should still work for long reads though, but double check). You will get a separate `.tab` report for each of your samples.
Create a file/digital sticky note with all of the file’s names: ls > list_samples.tab. You will need to run the python script kraken2_long_to_wide.py from your computer’s terminal in the same directory as you’ve kept your separate kraken reports: 

```
python kraken2_long_to_wide.py -i [list of your file names, separated by tab/space] -o kraken_analytic_matrix.csv
```

This will generate 2 files, `kraken_unclassifieds.csv` and `kraken_analytic_matrix.csv`.

## Step 2: Reformat Matrix

Then, you will get an output matrix. Should look something like:

![Kraken analyitic matrix opend in Excel](https://github.com/catrionelee/R_Workbook/blob/main/Pictures/kraken_analytic_matrix.png) 

You are going to have to open the `kraken_analytic_matrix.csv file` in excel and move the headers to align with their read counts, leaving A1 cell blank.

Then, insert 7 columns to the left of the A column. You will then select the entire A column and separate the column by a deliminater.

![Excel header directions to Text to Columns](https://github.com/catrionelee/R_Workbook/blob/main/Pictures/text_to_column.png)

![Excel Convert Text to Columns Wizard Step 1 of 3](https://github.com/catrionelee/R_Workbook/blob/main/Pictures/deliminated.png)

![Excel Convert Text to Columns Wizard Step 2 of 3](https://github.com/catrionelee/R_Workbook/blob/main/Pictures/delim_character.png)

![Excel Convert Text to Columns Wizard Step 3 of 3](https://github.com/catrionelee/R_Workbook/blob/main/Pictures/last_window.png)

Once you hit finish you’ll get:

![Formatted kraken matrix in excel](https://github.com/catrionelee/R_Workbook/blob/main/Pictures/expanded_matrix.png) 

Add the headers Domain, Kingdom, Phylum, Class, Order, Family, Genus, Species in the empty headers in row 1.



## Step 3: Importing into R

You will need to add the following R packages into your script: (* = follow install instructions below, they aren’t on CRAN and can’t be installed with `install.packages()`)
- microbiome*
- dplyr
- phyloseq*
- metagenomeSeq*
- tweeDEseq*
- microbiomeutilities*
- rstatix

For packages with an *, use:

```
install.packages(“BiocManager”)
BiocManager::install(“microbiome”)
BiocManager::install(“phyloseq”)
BiocManager::install(“metagenomeseq”)
BiocManager::install(“tweeDEseq”)
install.packages(“devtools”)
devtools::install_github(“microsud/microbiomeutilities”)
```

Then you’re going to import your matrix into R. You can subset the dataframe to remove phylum Chordata if you wish.

#### **Note: The following instructions are not comprehensive as they lack the R code, but are instead to be used as extensive comments to accompany the attached R script.**

## Step 3: Create a Phyloseq Object

Next create the OTU matrix `otumat`. Then the taxonomy matrix, `taxmat`. And finally combine into the phyloseq object, `phylo`. You then will read in the metadata, ensuring it’s a .csv file with the format: (each column name cannot contain spaces)

Column1 = Sample_ID, Column2 = Category1, Column3 = Category2, ...etc.

Create a dataframe for the environment (`enviro`) argument (of a phyloseq object) from each meaningful metadata category. Then merge `enviro` into the existing phyloseq object, `phylo`.
For data categories that are factors (discrete, like treatment groups) you need to define all possible values. Each level can have spaces. Ex.

```
factor(phylo@sam_data$Category1,
  levels = c(“Treatment 1”, “Treatment 2”, “Treatment 3”))
```

## Step 4: Generate Relative Abundances

This next section is a complicated nested for loop. It WILL take a lot of time to complete (around 20 mins, depending on how many samples you have). It’s purpose is to agglomerate all taxonomies of a given taxa rank, so that when visualizing, they are a single unit. 

You need to refine which taxa levels you want to investigate. (I did Phylum, Class, and Genus but you can choose whichever is relevant to your study. The more you add, the longer it will take.) You can’t just put Species though. If you do, only the rows with a species entry will be included, and all classifications that did not resolve to species will be discarded. Therefore, if you are analyzing non-species level classifications, you must specify each taxa rank of interest and it will generate a separate phyloseq object.

You also need to define certain metadata that cannot be grouped for analysis. (E.g. water and fecal microbiota cannot be compared (statistically) to each other as their environments differ so much. Or different animal hosts.) Keep these defined lists as continuous strings without spaces.

## Step 5: Read Normalization

For each dataframe that was generated from Step 4, you must normalize. There are two methods of normalization for read abundances (that I have found literature for): [Cumulative Sum Scaling (CSS)](https://doi.org/10.1038/nmeth.2658) or [Trimmed Mean m-value normalization (TMM)](https://doi.org/10.1186/gb-2010-11-3-r25). They are quite different in terms of coding.

### CSS Normalization
This method requires the package metagenomeSeq. From the phyloseq object, export it into an MRexperiment object (`metaSeqObject`). Then normalize with CSS and export to a dataframe. Then create a new OTU table from this dataframe. And then a new phyloseq object with the new OTU table, but the old taxonomy table and sample data. 

### TMM Normalization
This uses the package tweeDEseq. First you must normalize the OTU table and save it as a dataframe. Then create a new OTU table from the normalized dataframe. Then create a new phyloseq object that contains the new OTU table, but the old taxonomy table and sample data.

## Step 6: Analysis

If your analysis involved pooling samples, you can merge the samples together by category (e.g. treatment group) and have total sums.

I like to use the relative abundance of each phyloseq object using the microbiome package’s function. Then I aggregate the rare taxa. Viewing the number of taxa with ```ntaxa(relative_aggreagated_phylo_of_interest)``` in the console will reveal how many top taxa + 1 there are. Then to get the top taxa with their total abundances, you just specify the top number of taxa and it will aggregate the others into an “Other” group.
To visualize relative/total abundance, use the `plot_bar` function from phyloseq. You can use many of the functions from ggplot2 to customize it.

When trying to compare non-comparable groups (like different host animal) you must take the mean of the merged treatments. This involves knowing how many samples are in each grouping and manually dividing.

Fold-change can also be calculated and visualized. Use the `get_group_abundances function`, and store in a dataframe. Create an empty data frame with columns “Taxa Rank of Choice” and “Fold.Change”.  Then execute the for loop with the appropriate category and levels/treatment groups.
