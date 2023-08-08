run_packages <- function(){
      library(microbiome)
      library(dplyr)
      library(phyloseq )
      library(metagenomeSeq)
      library(tweeDEseq)
      library(microbiomeutilities)
      library(rstatix)
      library(ggplot2)
      library(ggpubr)
}

# Everytime you open R Studio, you must run this function
run_packages()




# Importing data into R -----------

kraken_matrix <- read.csv('kraken_analytic_matrix.csv')

# Optional: remove phylum Chordata
kraken_matrix <- subset(kraken_matrix, Phylum != "Chordata")

# Import metadata. Insert the name of your metadata file
metadata <- read.csv('')









# Create a Phyloseq Object -------------

# Generate OTU table. Replace 'firstSample:lastSample' with the column name of 
# the first and last sample names/ID's seperated by a ':'
otumat <- kraken_matrix %>% select(:)
otumat <- as.matrix(otumat)
row.names(otumat) <- paste0("OTU", 1:nrow(otumat))

# Generate taxonomy table (complete taxonomy of each OTU)
taxmat <- kraken_matrix %>% select(Domain:Species)
taxmat <- as.matrix(taxmat)
rownames(taxmat) <- paste0("OTU", 1:nrow(taxmat))

# Generate phyloseq element
OTU <- otu_table(otumat, taxa_are_rows = TRUE)
TAX <- tax_table(taxmat)
phylo <- phyloseq(OTU, TAX)


# Create metadata dataframe. Replace placeholders with your metadata info
enviro <- sample_data(data.frame(
      Category1 = metadata %>% select(Category1),
      Category2 = metadata %>% select(Category2),
      row.names = sample_names(phylo),
      stringsAsFactors = FALSE
))

# Merge metadata and phylo
phylo <- merge_phyloseq(phylo, enviro)

# Define factors in metadata. Replace placeholders with your metadata info
phylo@sam_data$AMU <-
      factor(phylo@sam_data$Category1,
             levels = c("Treatment 1", "Treatment 2", "Treatment 3"))









# Generate relative abundances by taxon ------------

# Define parameters
taxa <- c("Phylum", "Class", "Genus")
cat1_full <- c("Treatment 1", "Treatment 2", "Treatment 3")
cat1_abbr <- c("Trt1", "Trt1", "Trt1") # create simple 3-5 letter abbreviation

# To replace in for loop:
      # Category1
      # `Treatment 1` to `Treatment 3`
for (i in 1:length(taxa)) {
      # Tax glom
      pseq_taxa <- tax_glom(phylo, taxrank = taxa[[i]], NArm = TRUE)
      
      # Facets
      pseq_taxa@sam_data$Category1 <-
            factor(pseq_taxa@sam_data$Category1,
                   levels = c("Treatment 1", "Treatment 2", "Treatment 3"))
      #repeat for factoriizable metadata
      
      # Print outside of the for loop
      assign(paste0("pseq_", taxa[[i]]), pseq_taxa)
}









# CSS normalization -------------

# If you prefer, skip to TMM.
# This example will be done on the Phylum level. Repeat for all levels.

# Convert phyloseq object to MRexperiment object
metaSeqObject <- phyloseq_to_metagenomeSeq(pseq_Phylum)

# Normalize with CSS 
metaSeqObject_CSS <- cumNorm(metaSeqObject, p=cumNormStatFast(metaSeqObject))

# Export to matrix/dataframe from object
css_matrix <- as.data.frame(MRcounts(metaSeqObject_CSS, norm = TRUE, log = FALSE))

# New phyloseq object. Replace 'firstSample:lastSample' with the column name of 
# the first and last sample names/ID's seperated by a ':'
otumat_norm <- kraken_matrix %>% select(:)
otumat_norm <- as.matrix(otumat_norm)
row.names(otumat_norm) <- paste0("OTU", 1:nrow(otumat_norm))
OTU_norm <- otu_table(otumat_norm, taxa_are_rows = TRUE)

pseq_phylum_norm <- phyloseq(OTU_norm, 
                             tax_table(pseq_Phylum),
                             sample_data(pseq_Phylum))









# TMM normalization ------------

# This example will be done on the Phylum level. Repeat for all levels.

norm_phyla <- normalizeCounts(as(otu_table(pseq_Phylum), "matrix"),
                              method = c("TMM"))
norm_phyla_otu <- otu_table(norm_phyla, taxa_are_rows = TRUE)
pseq_phylum_norm <- phyloseq(norm_phyla_otu,
                             tax_table(pseq_Phylum),
                             sample_data(pseq_Phylum))









# Analysis: Merge by treatnment group for each taxa rank ---------

pseq_phylum_norm@sam_data$Cat1_f <- factor(pseq_phylum_norm@sam_data$Category1,
                                           levels = c("Treatment 1", 
                                                      "Treatment 2",
                                                      "Treatment 3"))
pseq_phylum_norm_mergedCat1 <- merge_samples(pseq_phylum_norm, "Cat1_f")



# Analysis: Get prevalent taxa -----------

pseq_phylum_norm_mergedCat1_rel <- microbiome::transform(
      pseq_phylum_norm_mergedCat1, "compositional")
pseq_phylum_norm_mergedCat1_rel1 <- aggregate_rare(
      pseq_phylum_norm_mergedCat1_rel,
      level = "Phylum",
      detection = 0.01,
      prevalence = 0.01)

x <- ntaxa(pseq_phylum_norm_mergedCat1_rel1) # This will give num prev taxa + 1

pseq_phylum_norm_mergedCat1_top <- aggregate_top_taxa2(
      pseq_phylum_norm_mergedCat1, top = x-1, level = "Phylum")



# Analysis: Bar plots of relative abundance -----------

# Tip: For every plot you make, label them as p or plot 1 and add 1 to each new

# Make a list where each top taxon is equal to a colour. I try to use a colour-
# blind friendly palette.
phyla_color = c("Actinobacteria"="#999999",
                "Bacteroidetes"="#E69F00",
                "Cyanobacteria"="#56B4E9",
                "Deinococcus-Thermus"="#009E73",
                "Euryarchaeota"="#F0E442",
                "Firmicutes"="#D55E00",
                "Proteobacteria"="#0072B2",
                "Spirochaetes"="#CC79A7",
                "Synergistetes"="#332288",
                "Verrucomicrobia"="#882255",
                "Other"="#000000")

plot1 <- plot_bar(pseq_phylum_norm_mergedCat1_top, fill = "Phylum") +
      scale_fill_manual(values = phyla_colour) +
      ylab("Normalized Phylum Abundance") +
      xlab("Category 1") +
      theme(legend.position = "bottom",
            axis.text.x = element_text(angle = 0, hjust = 0.5, size = 18),
            axis.text.y = element_text(size = 14),
            axis.title = element_text(size = 18),
            legend.text = element_text(size = 14)) +
      scale_y_continuous(labels = wrap_format(15))
plot1





