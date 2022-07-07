# This script provides the main entry point to this program.
# Allows a switch between NHTS years and keeps the processing in separate R scripts

#### SETUP PARAMETERS
#NHTSYEAR = 2001
NHTSYEAR = 2017
RAW_DIR = file.path('./data-raw', NHTSYEAR)
PARALLEL = TRUE

if(!dir.exists(RAW_DIR)) dir.create(RAW_DIR)
if(!dir.exists('./data')) dir.create('./data')

# Run the scripts in sequence
source('./R/s0_MakeNHTSFunctions.R')
source(sprintf('./R/s1_GetNHTSData_%s.R', NHTSYEAR))
source('./R/s2_MakeNHTSDataset.R')
source('./R/s3_StoreNHTSDataset.R')
