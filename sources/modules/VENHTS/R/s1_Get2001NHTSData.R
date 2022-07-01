#=====================
#Make2001NHTSDataset.R
#=====================
#This module creates a data frame of data from the publically available data
#from the 2001 National Household Travel Survey (NHTS) augmented with data on
#metropolitan area freeway supply and transit supply. The package produces a
#data frame of values by household.

#=======
#PURPOSE
#=======

#This script processes 2001 NHTS text files to create the household travel
#dataset to be used in model estimation. Data on freeway lane miles and
#bus equivalent transit revenue miles are added. A household dataframe (Hh_df)
#containing travel and other relevant data for each survey household.
# library(visioneval)

globalVariables("Per_df")
source('./R/s0_MakeNHTSFunctions.R')

# Because of a setting in .Rbuildignore, "data-raw" won't be present
# during the final build, but we will already have done all the
# following during the documentation phase, so we can jus skip it.

if(!dir.exists("data-raw")) dir.create("data-raw")


#Identify NHTS data directory
#----------------------------
#Compressed NHTS 2001 public use datasets are available in the following GitHub
#repository. This may change in the future.
Nhts2001Repo <-
  # "https://raw.githubusercontent.com/gregorbj/NHTS2001/master/data" # Deprecated 
  "https://nhts.ornl.gov/2001/download/Ascii.zip"

#Load NHTS household data
#------------------------
#Download data from repository and process if it has not already been done
if (!file.exists("data-raw/Hh_df.rda")) {
  Hh_df <- getZipDatasetFromRepo(Nhts2001Repo, "HHPUB")
  Keep_ <- c("HOUSEID", "AGE_P1", "AGE_P2", "AGE_P3", "AGE_P4", "AGE_P5",
             "AGE_P6", "AGE_P7", "AGE_P8", "AGE_P9", "AGE_P10", "AGE_P11",
             "AGE_P12", "AGE_P13", "AGE_P14", "CENSUS_D", "CENSUS_R", "DRVRCNT",
             "DRV_P1", "DRV_P2", "DRV_P3", "DRV_P4", "DRV_P5", "DRV_P6",
             "DRV_P7", "DRV_P8", "DRV_P9", "DRV_P10", "DRV_P11", "DRV_P12",
             "DRV_P13", "DRV_P14", "EXPFLHHN", "EXPFLLHH", "FLGFINCM",
             "HBHRESDN", "HBHUR", "HBPPOPDN", "HHC_MSA", "HHFAMINC", "HHINCTTL",
             "HHNUMBIK", "HHR_AGE", "HHR_DRVR", "HHR_RACE", "HHR_SEX", "HHSIZE",
             "HHVEHCNT", "HOMETYPE", "HTEEMPDN", "HTHRESDN", "HTHUR",
             "HTPPOPDN", "LIF_CYC", "MSAPOP", "MSACAT", "MSASIZE", "RAIL",
             "RATIO16V", "URBAN", "URBRUR", "WRKCOUNT", "WKR_P1", "WKR_P2",
             "WKR_P3", "WKR_P4", "WKR_P5", "WKR_P6", "WKR_P7", "WKR_P8",
             "WKR_P9", "WKR_P10", "WKR_P11", "WKR_P12", "WKR_P13", "WKR_P14",
             "CNTTDHH")
  Hh_df <- Hh_df[, Keep_]
  save(Hh_df, file = "data-raw/Hh_df.rda", compress = TRUE)
} else {
  #Otherwise read in from 'data-raw' directory
  load("data-raw/Hh_df.rda")
}
#Identify households that have expansion factor
AllTripsHh_ <- Hh_df$HOUSEID[!is.na(Hh_df$EXPFLLHH)]
#Limit households to those that have expansion factor
Hh_df <- Hh_df[Hh_df$HOUSEID %in% AllTripsHh_,]
#Convert field names to proper names
names(Hh_df) <- toProperName(names(Hh_df))
#Convert negative values to NA
Hh_df[Hh_df < 0] <- NA

#Load NHTS vehicle data
#----------------------
#Download data from repository and process if it has not already been done
if (!file.exists("data-raw/Veh_df.rda")) {
  Veh_df <- getZipDatasetFromRepo(Nhts2001Repo, "VEHPUB")
  Keep_ <-
    c("HOUSEID", "VEHID", "BESTMILE", "EIADMPG", "GSCOST", "VEHTYPE", "VEHYEAR",
      "VEHMILES" )
  Veh_df <- Veh_df[, Keep_]
  save(Veh_df, file = "data-raw/Veh_df.rda", compress = TRUE)
} else {
  load("data-raw/Veh_df.rda")
}
#Only include vehicle data for households that have expansion factor
Veh_df <- Veh_df[Veh_df$HOUSEID %in% AllTripsHh_,]
#Convert field names to proper names
names(Veh_df) <- toProperName(names(Veh_df))
#Convert Vehid to character
Veh_df$Vehid <- as.character(Veh_df$Vehid)
#Convert negative values to NA
Veh_df[Veh_df < 0] <- NA

#Load NHTS person data
#---------------------
#Download data from repository and process if it has not already been done
if (!file.exists("data-raw/Per_df.rda")) {
  Per_df <- getZipDatasetFromRepo(Nhts2001Repo, "PERPUB")
  Keep_ <-
    c("HOUSEID", "PERSONID", "COMMDRVR", "NBIKETRP", "NWALKTRP", "USEPUBTR",
      "WRKDRIVE", "WRKTRANS", "WORKER", "DTGAS", "DISTTOWK", "DRIVER", "R_AGE",
      "R_SEX")
  Per_df <- Per_df[, Keep_]
  save(Per_df, file = "data-raw/Per_df.rda", compress = TRUE)
} else {
  load("data-raw/Per_df.rda")
}
#Only include person data for households that have expansion factor
Per_df <- Per_df[Per_df$HOUSEID %in% AllTripsHh_,]
#Convert field names to proper names
names(Per_df) <- toProperName(names(Per_df))
#Create a unique person ID
Per_df$Personid <- paste0(Per_df$Houseid, doPadNum(Per_df$Personid))
#Convert negative values to NA
Per_df[Per_df < 0] <- NA

#Load NHTS daily trip data
#-------------------------
#Download data from repository and process if it has not already been done
if (!file.exists("data-raw/Dt_df.rda")) {
  Dt_df <- getZipDatasetFromRepo(Nhts2001Repo, "DAYPUB")
  Keep_ <-
    c("HOUSEID", "TDCASEID", "VEHID", "VEHUSED", "TRPHHVEH","PERSONID",
      "NUMONTRP", "TRPTRANS", "TRPMILES", "TRVL_MIN", "DWELTIME", "PSGR_FLG",
      "WHYFROM", "WHYTO", "VEHTYPE")
  Dt_df <- Dt_df[, Keep_]
  save(Dt_df, file = "data-raw/Dt_df.rda", compress = TRUE)
} else {
  load("data-raw/Dt_df.rda")
}
#Only include trip data for households that have expansion factor
Dt_df <- Dt_df[Dt_df$HOUSEID %in% AllTripsHh_,]
#Convert field names to proper names
names(Dt_df) <- toProperName(names(Dt_df))
#Convert Vehid to character
Dt_df$Vehid <- as.character(Dt_df$Vehid)
#Create a unique person ID
Dt_df$Personid <- paste0(Dt_df$Houseid, doPadNum(Dt_df$Personid))
#Convert negative values to NA
Dt_df[Dt_df < 0] <- NA
rm(AllTripsHh_)

#=======================================
#LOAD METROPOLITAN ROAD AND TRANSIT DATA
#=======================================

#Describe specifications for road supply data file
#-------------------------------------------------
RoadInp_ls <- visioneval::items(
  visioneval::item(
    NAME = visioneval::items(
      "MsaCode",
      "UrbanizedArea"),
    TYPE = "character",
    PROHIBIT = "NA",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  visioneval::item(
    NAME = visioneval::items(
      "RoadMiles",
      "TotalDvmt",
      "Population",
      "Area",
      "Density",
      "RoadMileCap",
      "FwyMiles",
      "FwyLaneMi"),
    TYPE = "double",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)

#Read in road supply data
#------------------------
Hwy2001_df <-
  visioneval::processEstimationInputs(
    RoadInp_ls,
    "highway_statistics.csv",
    "Make2001NHTSDataset")
rm(RoadInp_ls)

#Describe specifications for transit supply data file
#----------------------------------------------------
TransitInp_ls <- visioneval::items(
  visioneval::item(
    NAME = visioneval::items(
      "UZAName",
      "MSACode"),
    TYPE = "character",
    PROHIBIT = "",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  visioneval::item(
    NAME = visioneval::items(
      "BusEqRevMi",
      "UZAPop",
      "BusEqRevMiPC"),
    TYPE = "double",
    PROHIBIT = "< 0",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)

#Read in transit supply data
#---------------------------
Transit2001_df <-
  visioneval::processEstimationInputs(
    TransitInp_ls,
    "uza_bus_eq_rev_mi.csv",
    "Make2001NHTSDataset")
rm(TransitInp_ls)
rm(Nhts2001Repo)

