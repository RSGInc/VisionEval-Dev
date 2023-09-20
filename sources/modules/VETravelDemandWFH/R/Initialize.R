#============
#Initialize.R
#============

#<doc>
## Initialize Module
#### February 27, 2023
#
#Modules in the VETravelDemandWFH package includes modules that predicts the amount of time each worker in a houshold works from home and the resulting change in their commute distance
#
#It also includes modules that calculate household DVMT and alternate mode trips while accounting for teleworking behavior.
#
#The teleworking module uses a user input file 'azone_wkr_loc_type_occupation_prop.csv' to predict teleworking behavior.
#
#It is incumbent on the model user to identify if this file is consistent with 'azone_hh_loc_type_prop.csv'.
#
#This module includes a number of input checks to avoid data inconsistencies that could cause the model run to fail. Errors and warnings are produced to identify these errors and warnings:
#
#* The proportions of workers by location type for each Azone ('PropRuralOnSite', 'PropRuralMixed', 'PropRuralRemote' for Rural, 'PropTownOnSite', 'PropTownMixed', 'PropTownRemote' for Town, and 'PropMetroOnSite', 'PropMetroMixed', 'PropMetroRemote' for Metro in the 'azone_wkr_loc_type_occupation_prop.csv' file) are checked to confirm that they add up to 1 by location type. If the sum is off by more than 1%, then an error is identified. The error message identifies the Azones and Years that the data is incorrect. If the sum is off by less than 1% the proportions are rescaled to sum to 1 and a warning is identified. The warning message identifies the Azones and Years that the data doesn't sum to 1.
#* The proportions of workers by location type for each Azone ('PropRuralOnSite', 'PropRuralMixed', 'PropRuralRemote' for Rural, 'PropTownOnSite', 'PropTownMixed', 'PropTownRemote' for Town, and 'PropMetroOnSite', 'PropMetroMixed', 'PropMetroRemote' for Metro in the 'azone_wkr_loc_type_occupation_prop.csv' file) are checked to confirm that they are consisten with the existence of households in the location type by azone as proposed in the file 'azone_hh_loc_type_prop.csv'.
#</doc>


#=================================
#Packages used in code development
#=================================
#Un-comment following lines during code development. Re-comment when done.
#library(visioneval)
#library(VETravelDemandWFH)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================



#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
InitializeSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = item(
        "PropRuralOnSite",
        "PropRuralMixed",
        "PropRuralRemote",
        "PropTownOnSite",
        "PropTownMixed",
        "PropTownRemote",
        "PropMetroOnSite",
        "PropMetroMixed",
        "PropMetroRemote"
      ),
      TABLE = "Azone",
      GROUP = "Year",
      FILE = "azone_wkr_loc_type_occupation_prop.csv",
      TYPE = "double",
      UNITS = "proportion",
      SIZE = 0,
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = item(
        "PropRuralOnSite",
        "PropRuralMixed",
        "PropRuralRemote",
        "PropTownOnSite",
        "PropTownMixed",
        "PropTownRemote",
        "PropMetroOnSite",
        "PropMetroMixed",
        "PropMetroRemote"
      )
    ),
    item(
      NAME = items(
        "PropMetroHh",
        "PropTownHh",
        "PropRuralHh"
      ),
      FILE = "azone_hh_loc_type_prop.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = items(
        "Proportion of households residing in the metropolitan (i.e. urbanized) part of the Azone",
        "Proportion of households residing in towns (i.e. urban-like but not urbanized) in the Azone",
        "Proportion of households residing in rural (i.e. not urbanized or town) parts of the Azone"
      ),
      OPTIONAL = TRUE
    )
  )
)
#Save the data specifications list
#---------------------------------
#' Specifications list for Initialize module
#'
#' A list containing specifications for the Initialize module.
#'
#' @format A list containing 2 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#' }
#' @source Initialize.R script.
"InitializeSpecifications"
visioneval::savePackageDataset(InitializeSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================


#Main module function that checks whether urbanized area name is correct
#-----------------------------------------------------------------------
#' Check and adjust fuel and powertrain proportions inputs.
#'
#' \code{Initialize} checks the required worker proportion by azone, location type,
#' and occupation mix
#' to determine whether they each sum to 1, creates error and warning messages,
#' and makes adjustments if necessary. It also verifies the consistencey of the values
#' compared to the values in household proportion by location type and azone.
#'
#' This function processes the required  worker proportion by azone, location type,
#' and occupation mix inputs that have
#' been preprocessed by the processModuleInputs function. It checks the 
#' proportions to determine whether
#' they sum to 1. If the sum for a dataset differs from 1 by more than 1%, then
#' the function returns an error message identifying the problem dataset. If the
#' sum differs from 1 but the difference is 1% or less it is assumed that the
#' difference is due to rounding errors and function adjusts the proportions so
#' that they equal 1. In this case, a warning message is returned as well that
#' the framework will write to the log. It also verifies the consistencey of the values
#' compared to the values in household proportion by location type and azone.
#' If there are inconsistency then an error message is thrown showing the year
#' azone and the location type where the error was noted.
#'
#' @param L A list containing data from preprocessing supplied optional input
#' files returned by the processModuleInputs function. This list has two
#' components: Errors and Data.
#' @return A list that is the same as the input list with an additional
#' Warnings component.
#' @import visioneval
#' @export
Initialize <- function(L) {
  
  #Set up
  #------
  #Retrieve the model state
  G <- getModelState()
  #Initialize error and warnings message vectors
  Errors_ <- character(0)
  Warnings_ <- character(0)
  #Add the Marea identification in the Azone list
  # L$Data$Year$Azone$Marea <-
  #   G$Geo_df$Marea[match(L$Data$Year$Azone$Geo, G$Geo_df$Azone)]
  #Initialize output list with input values
  AzoneVars_ <- names(L$Data$Year$Azone)
  NotSaveVars_ <-
    c("PropMetroHh", "PropTownHh", "PropRuralHh")
  if(all(NotSaveVars_ %in% AzoneVars_)){
    OutAzoneVars_ <- AzoneVars_[-which(AzoneVars_ %in% NotSaveVars_)]
  } else {
    OutAzoneVars_ <- AzoneVars_
  }
  Out_ls <- L
  Out_ls$Data$Year$Azone <- Out_ls$Data$Year$Azone[OutAzoneVars_]
  
  #Define function to check whether proportions add to 1 and adjust
  #----------------------------------------------------------------
  checkProps <- function(Names_, Geo, File) {
    Values_df <- data.frame(L$Data$Year[[Geo]][c("Year", "Geo", Names_)])
    Values_df$Geo <- as.character(Values_df$Geo)
    Values_df$Year <- as.character(Values_df$Year)
    Yr <- unique(Values_df$Year)
    for (yr in Yr) {
      V_df <- Values_df[Values_df$Year == yr,]
      SkipRows_ <- rowSums(V_df[,Names_]) == 0
      SumDiff_ <- abs(1 - rowSums(V_df[,Names_]))
      SumDiff_[SkipRows_] <- 0
      HasErr_ <- SumDiff_ > 0.01
      HasWarn_ <- SumDiff_ > 0 & SumDiff_ < 0.01
      if (any(HasErr_)) {
        ErrAzones_ <- V_df$Geo[HasErr_]
        Msg <- paste0(
          "Error in input file '", File, "' for year ", yr,
          " and the following Azones: ",
          paste(ErrAzones_, collapse = ", "), ". ",
          "The sum of values for (", paste(Names_, collapse = ", "),
          ") are off by more than 1%. They should add up to 1."
        )
        Errors_ <<- c(Errors_, Msg)
      }
      if (any(HasWarn_)) {
        WarnAzones_ <- V_df$Geo[HasWarn_]
        Msg <- paste0(
          "Warnings for input file '", File, "' for year '", yr,
          "' and the following Azones: ",
          paste(WarnAzones_, collapse = ", "), ". ",
          "The sum of values for (", paste(Names_, collapse = ", "),
          ") are not equal to 1 but are off by 1% or less. ",
          "They have been adjusted to add up to 1."
        )
        Warnings_ <<- c(Warnings_, Msg)
        for (az in WarnAzones_) {
          Values_ <- V_df[V_df$Geo == az, Names_]
          AdjValues_ <- Values_ / sum(Values_)
          Values_df[Values_df$Year == yr & Values_df$Geo == az, Names_] <-
            AdjValues_
        }
      }
    }
    as.list(Values_df[,Names_])
  }
  
  #Check and adjust household location type proportions
  #----------------------------------------------------
  LocType_ <- c("Rural", "Town", "Metro")
  TeleWork_ <- c("OnSite", "Mixed", "Remote")
  for (loc_type in LocType_) {
    Names_ <- paste0("Prop", loc_type, TeleWork_)
    if (all(Names_ %in% names(Out_ls$Data$Year$Azone))) {
      Out_ls$Data$Year$Azone[Names_] <-
        checkProps(Names_, "Azone", "azone_wkr_loc_type_occupation_prop.csv")
    } else {
      Msg <- paste0(
        "azone_wkr_loc_type_occupation_prop.csv input file is present but not complete. ",
        "Not all the required fields are present. The required fields are: ",
        paste(Names_, collapse = ", ")
      )
      Errors_ <- c(Errors_, Msg)
    }
    rm(Names_)
  }
 
  #Check consistency of location type area and activity
  #----------------------------------------------------
  #Only check if no other errors identified
  if(all(NotSaveVars_ %in% names(Out_ls$Data$Year$Azone))){
    if (length(Errors_) == 0) {
      #Iterate through years and check values
      Yr <- unique(L$Data$Year$Azone$Year)
      Values_df <- data.frame(Out_ls$Data$Year$Azone)
      Values_df$Geo <- as.character(Values_df$Geo)
      Values_df$Year <- as.character(Values_df$Year)
      for (yr in Yr) {
        IsYear <- L$Data$Year$Azone$Year == yr
        V_df <- Values_df[IsYear,]
        #Check if there are valid proportions
        for(loc_type in LocType_){
          Names_ <- paste0("Prop", loc_type, TeleWork_)
          HhNames_ <- paste0("Prop", loc_type, "Hh")
          WrkProps_ <- rowSums(V_df[,Names_])
          HhProps_ <- data.frame(L$Data$Year$Azone[HhNames_])[IsYear,]
          # Check if there are positive proportions where households exists
          ValidProps_ <- WrkProps_>=HhProps_
          BothNAs_ <- is.na(WrkProps_) & is.na(HhProps_)
          ValidProps_[is.na(ValidProps_) & !BothNAs_] <- FALSE
          if (any(!ValidProps_)) {
            ErrAzones_ <- V_df[!ValidProps_, "Geo"]
            Msg <- paste0(
              "Error in the input file 'azone_wkr_loc_type_occupation_prop.csv", "' for year ", yr,
              " and the following Azones: ",
              paste(ErrAzones_, collapse = ", "), ". ",
              "The values are inconsistent for (", paste(Names_, collapse = ", "),
              ") compared to values for (", HhNames_, ") in 'azone_hh_loc_type_prop.csv' file."
            )
            Errors_ <- c(Errors_, Msg)
          }
          
        }
      }
    }
  }
  
  #Add Errors and Warnings to Out_ls and return
  #--------------------------------------------
  Out_ls$Errors <- Errors_
  Out_ls$Warnings <- Warnings_
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("Initialize")

#Test code to perform additional checks on input files. Return input list
#(TestDat_) to use for developing the Initialize function.
#-------------------------------------------------------------------------------
# source("tests/scripts/test_functions.R")
# #Set up test data
# setUpTests(list(
#   TestDataRepo = "../Test_Data/VE-State",
#   DatastoreName = "Datastore.tar",
#   LoadDatastore = TRUE,
#   TestDocsDir = "vestate",
#   ClearLogs = TRUE
# ))
# #Return test dataset
# TestDat_ <- testModule(
#   ModuleName = "Initialize",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_
# R <- Initialize(TestDat_)

#Test code to check everything including running the module and checking whether
#the code runs completely and produces desired results
#-------------------------------------------------------------------------------
# source("tests/scripts/test_functions.R")
#Set up test data
# setUpTests(list(
#   TestDataRepo = "../Test_Data/VE-State",
#   DatastoreName = "Datastore.tar",
#   LoadDatastore = TRUE,
#   TestDocsDir = "vestate",
#   ClearLogs = TRUE
# ))
# TestDat_ <- testModule(
#   ModuleName = "Initialize",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
