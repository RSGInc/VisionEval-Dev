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

#==================
#LOAD NHTS DATASETS
#==================

#MSA Crosswalk
if(!file.exists("./inst/extdata/msa_xwalk.csv")) {
  # Red in cbsa to fips
  cbsa2fips <- read.csv('./inst/extdata/cbsa2fipsxw.csv')
  
  # Set text file loading widths
  msa_widths <- read.csv('./inst/extdata/99mfips_coding.txt',sep="\t")
  msa_widths <- setNames(msa_widths$width, msa_widths$label)
  
  # Read in fips to MSA
  fips2msa <- read.fwf('./inst/extdata/99mfips.txt', 
                       widths = msa_widths,
                       colClasses='character')
  
  # Formatting
  fips2msa <- fips2msa[,-which('Blank' == names(msa_widths))]
  colnames(fips2msa) <- c('MSA', 'PMSA','AltCMSA','STATE',
                           'COUNTY','CENTRAL','FIPS','NAME')
  fips2msa <- fips2msa[!is.na(fips2msa$MSA),]
  
  # Create xwalk
  msa_xwalk <- merge(
    fips2msa[,c('MSA','STATE','COUNTY')],
    cbsa2fips[,c('cbsacode','fipsstatecode','fipscountycode')],
    by.x = c('STATE','COUNTY'),
    by.y = c('fipsstatecode','fipscountycode'))
  
  names(msa_xwalk)[names(msa_xwalk) == 'cbsacode'] <- "CBSA"
  
  # smaller than 1 million
  msa_xwalk <- rbind(msa_xwalk, data.frame(CBSA='XXXXX', MSA='XXX'))
  
  write.csv(msa_xwalk, "./inst/extdata/msa_xwalk.csv", row.names = F)
} else {
  msa_xwalk <- read.csv("./inst/extdata/msa_xwalk.csv", colClasses = 'character')
}

# Remove FIPS precisions in msa_xwalk
msa_xwalk <- unique(msa_xwalk[,c('CBSA','MSA')])

# NHTS column xwalk
colxwalk <- read.csv('./inst/extdata/nhts_xwalk.csv')



# Because of a setting in .Rbuildignore, "data-raw" won't be present
# during the final build, but we will already have done all the
# following during the documentation phase, so we can jus skip it.

if(!dir.exists(RAW_DIR)) dir.create(RAW_DIR)#Identify NHTS data directory
#----------------------------
#Compressed NHTS 2001 public use datasets are available in the following GitHub
#repository. This may change in the future.
Nhts2017Repo <-
  #"https://raw.githubusercontent.com/gregorbj/NHTS2001/master/data"
  'https://nhts.ornl.gov/assets/2016/download/csv.zip'



if (!file.exists(file.path(RAW_DIR, "nhts_dflist.rda"))) {
  # Load the full data set in
  tf <- tempfile()
  download.file(Nhts2017Repo, tf)
  
  flist <- unzip(tf, list = TRUE)$Name
  flist <- flist[grepl('.csv', flist)]
  
  # Read all the files into memory
  raw_dflist <- lapply(flist, function(x) {
    con <- unz(tf, x)
    read.csv(con)
  })
  names(raw_dflist) <- gsub('.csv', '', flist)
  unlink(tf)
  rm(tf, flist)
  save(raw_dflist, file = file.path(RAW_DIR, "nhts_dflist.rda"), compress = TRUE)
} else {
  #Otherwise read in from 'data-raw' directory
  load(file.path(RAW_DIR, "nhts_dflist.rda"))
}


#Load NHTS household data
#------------------------
#Download data from repository and process if it has not already been done
if (!file.exists(file.path(RAW_DIR, "Hh_df.rda"))) {
  # Hh_df <- read.csv(unz(tf, "hhpub.csv"))
  Hh_df <- raw_dflist[['hhpub']]
  # Keep_ <- colxwalk[colxwalk$File=='hh','NHTS2017']
  # Keep_ <- Keep_[Keep_!=""]
  Keep_ <- 
    c("HOUSEID", "CENSUS_D", "CENSUS_R", "DRVRCNT", "HBRESDN", "HBHUR",
      "HBPPOPDN", "HHFAMINC", "HH_RACE", "HHSIZE", "HHVEHCNT", "HTEEMPDN",
      "HTRESDN", "HTPPOPDN", "LIF_CYC", "MSACAT", "MSASIZE", "RAIL", "URBAN",
      "URBRUR", "WRKCOUNT", "CNTTDHH","WTHHFIN","HH_CBSA")
  Hh_df <- Hh_df[, Keep_]
  
  
  # HH_CBSA to HHC_MSA
  Hh_df <- merge(Hh_df, msa_xwalk[,c('MSA','CBSA')], 
                 by.x='HH_CBSA', by.y = 'CBSA',
                 all.x = T)
  
  # Pull in Age columns
  age_df <- reshape(raw_dflist[['perpub']][ , c('HOUSEID', 'PERSONID', 'R_AGE')],
                    idvar = 'HOUSEID', timevar = 'PERSONID', times='R_RAGE',
                    direction='wide')
  colnames(age_df)[-1] <- paste0('AGE_P', 1:13)
  age_df$AGE_P14 <- NA
  Hh_df <- merge(Hh_df, age_df)
  
  # Pull in driver status
  drv_df <- reshape(raw_dflist[['perpub']][ , c('HOUSEID', 'PERSONID', 'DRIVER')],
                    idvar = 'HOUSEID', timevar = 'PERSONID', times='DRIVER',
                    direction='wide')
  colnames(drv_df)[-1] <- paste0('DRV_P', 1:13)
  drv_df$DRV_P14 <- NA
  Hh_df <- merge(Hh_df, drv_df)
  
  # Pull in worker status
  wrk_df <- reshape(raw_dflist[['perpub']][ , c('HOUSEID', 'PERSONID', 'WORKER')],
                    idvar = 'HOUSEID', timevar = 'PERSONID', times='WORKER',
                    direction='wide')
  colnames(wrk_df)[-1] <- paste0('WKR_P', 1:13)
  wrk_df$WKR_P14 <- NA
  Hh_df <- merge(Hh_df, wrk_df)
  
  #RATIO16V, ratio of 16+ HH members to HH vehicles
  RATIO16V <- merge(raw_dflist[['hhpub']][c('HOUSEID','HHVEHCNT')],
                    as.data.frame(
                      table(raw_dflist[['perpub']][raw_dflist[['perpub']]$R_AGE>=16, 'HOUSEID'])
                    ),
                    by.x='HOUSEID', by.y='Var1'
  )
  
  RATIO16V$RATIO16V <- RATIO16V$Freq / RATIO16V$HHVEHCNT
  Hh_df <- merge(Hh_df, RATIO16V[,c('HOUSEID',"RATIO16V")])
  
  # Sex, Age, Race of household respondent
  HHR_ <- raw_dflist[['perpub']][
    raw_dflist[['perpub']]$PERSONID==1,
    c('HOUSEID','R_SEX','R_AGE', 'R_RACE','DRIVER')
  ]
  Hh_df <- merge(HHR_, Hh_df, by='HOUSEID')
  
  # HHINCTTL 
  Hh_df$HHINCTTL <- Hh_df$HHFAMINC
  
  # Rename HTHUR
  renames <- c('HTHUR' = 'HBHUR',
               'R_SEX' = 'HHR_SEX',
               'R_AGE' = 'HHR_AGE',
               'R_RACE' = 'HHR_RACE',
               'DRIVER' = 'HHR_DRVR',
               'WTHHFIN' = 'EXPFLLHH',
               'MSA' = 'HHC_MSA')
  
  for(n in names(renames)) {
    names(Hh_df)[names(Hh_df) == n] <- renames[n]
  }
  
  rm(HHR_, wrk_df, drv_df, age_df, RATIO16V, n, renames)
  save(Hh_df, file = file.path(RAW_DIR, "Hh_df.rda"), compress = TRUE)
} else {
  #Otherwise read in from 'data-raw' directory
  load(file.path(RAW_DIR, "Hh_df.rda"))
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
if (!file.exists(file.path(RAW_DIR, "Veh_df.rda"))) {
  # Veh_df <- read.csv(unz(tf, "vehpub.csv"))
  Veh_df <- raw_dflist[['vehpub']]
  Keep_ <-
    c("HOUSEID", "VEHID", "BESTMILE", "FEGEMPG", "GSCOST",
      "VEHTYPE", "VEHYEAR","ANNMILES" )
  Veh_df <- Veh_df[, Keep_]
  
  # Rename EIADMPG
  names(Veh_df)[names(Veh_df) == 'FEGEMPG'] <- 'EIADMPG'
  names(Veh_df)[names(Veh_df) == 'ANNMILES'] <- 'VEHMILES'
  
  save(Veh_df, file = file.path(RAW_DIR, "Veh_df.rda"), compress = TRUE)
} else {
  load(file.path(RAW_DIR, "Veh_df.rda"))
}
#Only include vehicle data for households that have expansion factor
Veh_df <- Veh_df[Veh_df$HOUSEID %in% AllTripsHh_,]
#Convert field names to proper names
names(Veh_df) <- toProperName(names(Veh_df))
#Convert Vehid to character
Veh_df$Vehid <- as.character(Veh_df$Vehid)
#Convert negative values to NA
Veh_df[Veh_df < 0] <- NA


#Load NHTS daily trip data
#-------------------------
#Download data from repository and process if it has not already been done
if (!file.exists(file.path(RAW_DIR, "Dt_df.rda"))) {
  # Dt_df <- read.csv(unz(tf, "trippub.csv"))
  Dt_df <- raw_dflist[['trippub']]
  Keep_ <-
    c("HOUSEID", "TDCASEID", "VEHID", "TRPHHVEH","PERSONID",
      "NUMONTRP", "TRPTRANS", "TRPMILES", "TRVLCMIN", "DWELTIME", "PSGR_FLG",
      "WHYFROM", "WHYTO", "VEHTYPE")
  Dt_df <- Dt_df[, Keep_]
  
  # Rename TRVL_MIN
  names(Dt_df)[names(Dt_df) == 'TRVLCMIN'] <- 'TRVL_MIN'
  
  # Pull in VEHUSED column from VEHID
  Dt_df$VEHUSED <- Dt_df$VEHID
  
  save(Dt_df, file = file.path(RAW_DIR, "Dt_df.rda"), compress = TRUE)
} else {
  load(file.path(RAW_DIR, "Dt_df.rda"))
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


#Load NHTS person data
#---------------------
#Download data from repository and process if it has not already been done
if (!file.exists(file.path(RAW_DIR, "Per_df.rda"))) {
  # Per_df <- read.csv(unz(tf, "perpub.csv"))
  Per_df <- raw_dflist[['perpub']]
  Keep_ <-
    c("HOUSEID", "PERSONID", "NBIKETRP", "NWALKTRP", "USEPUBTR",
      "WRKTRANS", "WORKER", "DISTTOWK17", "DRIVER", "R_AGE",
      "R_SEX")
  Per_df <- Per_df[, Keep_]
  
  # Pull GASPRICE from hosuehold file as PRICE
  Per_df <- merge(Per_df, raw_dflist[['hhpub']][, c('HOUSEID', 'PRICE')])
  
  # Rename DISTTOWK17 and GASPRICE
  names(Per_df)[names(Per_df) == 'DISTTOWK17'] <- 'DISTTOWK'
  names(Per_df)[names(Per_df) == 'PRICE'] <- 'DTGAS'
  
  save(Per_df, file = file.path(RAW_DIR, "Per_df.rda"), compress = TRUE)
} else {
  load(file.path(RAW_DIR, "Per_df.rda"))
}
#Only include person data for households that have expansion factor
Per_df <- Per_df[Per_df$HOUSEID %in% AllTripsHh_,]
#Convert field names to proper names
names(Per_df) <- toProperName(names(Per_df))
#Create a unique person ID
Per_df$Personid <- paste0(Per_df$Houseid, doPadNum(Per_df$Personid))
#Convert negative values to NA
Per_df[Per_df < 0] <- NA


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

rm(colxwalk, AllTripsHh_)
