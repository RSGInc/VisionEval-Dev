#===================
#CVAVOrientation.R
#===================

#<doc>
#
## CVAVOrientation Module
#### January 5, 2022
#
#
### Model Parameter Estimation
#
#.
#
### How the Module Works
#
# * The module calculates the likelihood of a household owning a level 5
#   autonomous vehicle. A random draw then decides whether the household
#   chooses to own a level 5 AV
# * 
#
#
#
#</doc>


#=================================
#Packages used in code development
#=================================



#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================



#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CVAVOrientationSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify input data
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "HhId",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "HhId",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CVAVOrientation module
#'
#' A list containing specifications for the CVAVOrientation module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CVAVOrientation.R script.
"CVAVOrientationSpecifications"
visioneval::savePackageDataset(CVAVOrientationSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#
#
#
#

#Ancillary functions
#--------------------


#Main module function that assigns CV/AV orientation to household vehicles
#-------------------------------------------------------------------------
#' Assign level of autonomous to household vehicles
#'
#' \code{CVAVOrientation} assigns level of automation to household vehicles
#'
#' @param L A list containing data defined by the module specification.
#' @return A list containing data produced by the function consistent with the
#' module specifications.
#' @name CVAVOrientation
#' @import visioneval
#' @export
CVAVOrientation <- function(L) {
  
  #Set up
  #------
  #Copy portions of inputs list to outputs so that outputs exist to meet Set
  #specifications regardless of whether base year or other year
  Out_ls <- list(
  )
  #Function to remove attributes
  unattr <- function(X_) {
    attributes(X_) <- NULL
    X_
  }
  
  
  #Return the results
  #------------------
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("CVAVOrientation")

#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# #Load libraries and test functions
# library(visioneval)
# library(filesstrings)
# source("tests/scripts/test_functions.R")
# load("data/RoadDvmtModel_ls.rda")
# #Set up test environment
# TestSetup_ls <- list(
#   TestDataRepo = "../Test_Data/VE-CLMPO",
#   DatastoreName = "Datastore.tar",
#   LoadDatastore = TRUE,
#   TestDocsDir = "veclmpo",
#   ClearLogs = TRUE,
#   # SaveDatastore = TRUE
#   SaveDatastore = FALSE
# )
# setUpTests(TestSetup_ls)
# #Run test module
# TestDat_ <- testModule(
#   ModuleName = "CVAVOrientation",
#   LoadDatastore = TRUE,
#   SaveDatastore = FALSE,
#   DoRun = FALSE,
#   RunFor = "BaseYear"
# )
# L <- TestDat_$L
# R <- CVAVOrientation(L)
#
# TestDat_ <- testModule(
#   ModuleName = "CVAVOrientation",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE,
#   RunFor = "BaseYear"
# )
#
# TestDat_ <- testModule(
#   ModuleName = "CVAVOrientation",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE,
#   RunFor = "NotBaseYear"
# )

