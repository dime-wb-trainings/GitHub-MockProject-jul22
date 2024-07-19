# Main Script for Datawork Exercise
# Load necessary packages --------------------------

# uncomment this line if pacman is not installed
# install.packages("pacman")

packages <- c("here", # to manage file paths
              "tidyr", # For data tidying
              "dplyr", # For data manipulation
              "haven", # For working with 'foreign' datasets like Stata, 
              "ggplot2", # create graphs, 
              "scales", # for scales in plots
              "modelsummary", # descriptive stat tables
              "fixest", # regression
              "huxtable", # save to excel
              "forcats", # for factor manipulation
              "assertthat", # review coding
              "ggpubr",
              "openxlsx",
              "writexl") # combining and arranging plots


pacman::p_load(packages,
               character.only = TRUE,
               install = FALSE) # Change to TRUE to install the necessary packages


options(scipen = 999) # to work without scientific notation

#  Load data ----

# Set the data path (replace 'your_data_path' with the actual path in your computer)
# This is the second root of our project
# Our first root is the code and the outputs folder, which is locked by the Rproj, 
# so we only need to worry to set up the second root. 

data_path <- "C:/Users/wb614536/OneDrive - WBG/Documents/GithubTraining/Data"

# Source the R scripts in the correct order
source("Code/01-processing-data.R")
source("Code/02-data-construction.R")
