#==========================
#PredictWFH.R
#==========================
#
#<doc>
#
## PredictWFH Module
#### June 13, 2022
#
#This module predicts the amount of time each worker in a household works from home and the resulting change in their commute distance
#
### Model Parameter Estimation
#
#See data-raw/DriversModel_df.R.
#
### How the Module Works
#
#The module assigns amount of teleworking to each worker in the household and the resulting change in their commute distance.
#
#</doc>

#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
# 

#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
PredictWFHSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  Inp = items(
    item(
      NAME = item(
        "MixedWorkFromHome",
        "MixedNoTelework",
        "MixedTelework1to3DaysPerMonth",
        "MixedTelework1DayPerWeek",
        "MixedTelework2to3DaysPerWeek",
        "MixedTelework4DaysPerWeek",
        "MixedTelework5DaysPerWeek",
        "OnSiteWorkFromHome",
        "OnSiteNoTelework",
        "OnSiteTelework1to3DaysPerMonth",
        "OnSiteTelework1DayPerWeek",
        "OnSiteTelework2to3DaysPerWeek",
        "OnSiteTelework4DaysPerWeek",
        "OnSiteTelework5DaysPerWeek",
        "RemoteWorkFromHome",
        "RemoteNoTelework",
        "RemoteTelework1to3DaysPerMonth",
        "RemoteTelework1DayPerWeek",
        "RemoteTelework2to3DaysPerWeek",
        "RemoteTelework4DaysPerWeek",
        "RemoteTelework5DaysPerWeek"
      ),
      TABLE = "Region",
      GROUP = "Year",
      FILE = "region_telework.csv",
      TYPE = "double",
      UNITS = "proportion",
      SIZE = 0,
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      DESCRIPTION = item(
        "MixedWorkFromHome",
        "MixedNoTelework",
        "MixedTelework1to3DaysPerMonth",
        "MixedTelework1DayPerWeek",
        "MixedTelework2to3DaysPerWeek",
        "MixedTelework4DaysPerWeek",
        "MixedTelework5DaysPerWeek",
        "OnSiteWorkFromHome",
        "OnSiteNoTelework",
        "OnSiteTelework1to3DaysPerMonth",
        "OnSiteTelework1DayPerWeek",
        "OnSiteTelework2to3DaysPerWeek",
        "OnSiteTelework4DaysPerWeek",
        "OnSiteTelework5DaysPerWeek",
        "RemoteWorkFromHome",
        "RemoteNoTelework",
        "RemoteTelework1to3DaysPerMonth",
        "RemoteTelework1DayPerWeek",
        "RemoteTelework2to3DaysPerWeek",
        "RemoteTelework4DaysPerWeek",
        "RemoteTelework5DaysPerWeek"
      )
    )
  ),
  #Specify data to be loaded from data store
  Get = visioneval::items(
    visioneval::item(
      NAME = "HhId",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    visioneval::item(
      NAME = "WkrId",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    visioneval::item(
      NAME = "Azone",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    visioneval::item(
      NAME = "Bzone",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "none",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    visioneval::item(
      NAME = "DistanceToWork",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      NAVALUE = "-1",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    visioneval::item(
      NAME =
        items("Age0to14",
              "Age15to19",
              "Wkr15to19",
              "Wkr20to29",
              "Wkr30to54",
              "Wkr55to64",
              "Wkr65Plus"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    visioneval::item(
      NAME = "Income",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2017",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    visioneval::item(
      NAME = "LifeCycle",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = -1,
      PROHIBIT = "",
      ISELEMENTOF = c("00", "01", "02", "03", "04", "09", "10"),
      SIZE = 2
    ),
    visioneval::item(
      NAME = "HhId",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    visioneval::item(
      NAME = "Azone",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "none",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    visioneval::item(
      NAME = "Bzone",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "none",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    visioneval::item(
      NAME = "Bzone",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "none",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    visioneval::item(
      NAME = "AreaType",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    visioneval::item(
      NAME = "LocType",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    visioneval::item(
      NAME = "LocType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    visioneval::item(
      NAME = "D1B",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "PRSN/ACRE",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    visioneval::item(
      NAME = "D1C",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "PRSN/ACRE",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = item(
        "MixedWorkFromHome",
        "MixedNoTelework",
        "MixedTelework1to3DaysPerMonth",
        "MixedTelework1DayPerWeek",
        "MixedTelework2to3DaysPerWeek",
        "MixedTelework4DaysPerWeek",
        "MixedTelework5DaysPerWeek",
        "OnSiteWorkFromHome",
        "OnSiteNoTelework",
        "OnSiteTelework1to3DaysPerMonth",
        "OnSiteTelework1DayPerWeek",
        "OnSiteTelework2to3DaysPerWeek",
        "OnSiteTelework4DaysPerWeek",
        "OnSiteTelework5DaysPerWeek",
        "RemoteWorkFromHome",
        "RemoteNoTelework",
        "RemoteTelework1to3DaysPerMonth",
        "RemoteTelework1DayPerWeek",
        "RemoteTelework2to3DaysPerWeek",
        "RemoteTelework4DaysPerWeek",
        "RemoteTelework5DaysPerWeek"
      ),
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      SIZE = 0,
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    visioneval::item(
      NAME = "Azone",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "none",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
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
      TYPE = "double",
      UNITS = "proportion",
      SIZE = 0,
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = visioneval::items(
    visioneval::item(
      NAME = "Occupation",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = NA,
      PROHIBIT = c(""),
      ISELEMENTOF = c("on-site", "mixed", "remote"),
      SIZE = 0,
      DESCRIPTION = "What is the workers occupation type?"
    ),
    visioneval::item(
      NAME = "WorkFromHome",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = as.character(NA),
      PROHIBIT = c(""),
      ISELEMENTOF = c("Yes", "No", as.character(NA)),
      SIZE = 3,
      DESCRIPTION = "Does the worker work from home (all of the time, not telework)?"
    ),
    visioneval::item(
      NAME = "TeleWork",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = as.character(NA),
      PROHIBIT = c(""),
      ISELEMENTOF = c("Yes", "No", as.character(NA)),
      SIZE = 3,
      DESCRIPTION = "Does the worker telework (sometime work from home in a job with an out of home workplace)"
    ),
    visioneval::item(
      NAME = "TeleWorkDays",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE =  as.character(NA),
      PROHIBIT = c(""),
      ISELEMENTOF = c("1-3 days per month",
                      "1 day per week",
                      "2-3 days per week",
                      "4 days per week",
                      "5+ days per week", as.character(NA)),
      SIZE = 20,
      DESCRIPTION = "How often does the worker telework (in days per week or per month)"
    ),
    visioneval::item(
      NAME = items(
        "CommuteDistance",
        "CommuteDistanceAdj"),
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Commute Distance for the worker",
        "Commute distance adjusted for any teleworking")
    ),
    visioneval::item(
      NAME = items(
        "WorkFromHomeFraction"),
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Proportion of the time worked from home")
    ),
    visioneval::item(
      NAME = items(
        "CommuteDistanceAdj"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Commute Distance for the worker",
        "Commute distance adjusted for any teleworking")
    ),
    visioneval::item(
      NAME = items(
        "FractionWorkersAtHome"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Proportion of workers in the household at home")
    )
  )
)


#Save the data specifications list
#---------------------------------
#' Specifications list for PredictDrivers module
#'
#' A list containing specifications for the PredictDrivers module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
"PredictWFHSpecifications"
visioneval::savePackageDataset(PredictWFHSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function predicts the occupation of workers in each
#household and then predicts whether they work from home full time. 
#It uses the model objects in data/OccShares_df.rda and data/WorkFromHome_df.rda.

#Main module function that predicts Occupation and Work from Home for each worker
#--------------------------------------------------------------------
#' Main module function to predict Occupation and Work from Home for each worker
#'
#' \code{PredictWFH} predicts Occupation and Work from Home for each worker.
#' It uses the model objects in data/OccShares_df.rda and data/WorkFromHome_df.rda.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @import data.table
#' @importFrom MASS polr
#' @export
PredictWFH <- function(L) {
  
  set.seed(L$G$Seed)
  
  hh <- as.data.table(L$Year$Household)
  worker <- as.data.table(L$Year$Worker)
  bzone <- as.data.table(L$Year$Bzone)
  region_telework <- as.data.table(L$Year$Region)
  occ_shares <- as.data.table(L$Year$Azone)
  
  # Scenario Targets
  # ================
  
  # Process the targets for the different models
  occupations <- c("Mixed", "OnSite", "Remote")
  telework_levels_workfromhome <- "WorkFromHome"
  telework_levels_telework <- "NoTelework"
  telework_levels_teleworkdays <- c("Telework1to3DaysPerMonth", "Telework1DayPerWeek", 
                                    "Telework2to3DaysPerWeek", "Telework4DaysPerWeek",
                                    "Telework5DaysPerWeek")
  telework_levels <- c(telework_levels_workfromhome,
                       telework_levels_telework,
                       telework_levels_teleworkdays)
  
  telework_targets <- paste0(rep(occupations, each = length(telework_levels)), 
                             rep(telework_levels, length(occupations)))
  
  targets_all <- melt.data.table(region_telework[,..telework_targets],
                                 measure.vars = telework_targets,
                                 variable.name = "OccupationTeleWorkLevel",
                                 value.name = "Target",
                                 variable.factor = FALSE)
  
  # Normalize overall
  # Separate out the field names
  
  targets_all[, Occupation := ifelse(grepl("Mixed", OccupationTeleWorkLevel), "Mixed",
                                     ifelse(grepl("OnSite", OccupationTeleWorkLevel), "OnSite", "Remote"))]
  targets_all[, TeleWorkLevel := ifelse(Occupation == "Mixed", gsub("Mixed","", OccupationTeleWorkLevel), 
                                        ifelse(Occupation == "OnSite", gsub("OnSite","", OccupationTeleWorkLevel),
                                               gsub("Remote","", OccupationTeleWorkLevel)))]
  
  targets_all[, Target := Target/sum(Target), by = Occupation]
  
  # Normalize the telework target and the telework days targets
  # NoTelework + plus the days should sum to one
  targets_all[!TeleWorkLevel %in% telework_levels_workfromhome, 
              Target := Target/sum(Target), 
              by = Occupation]
  targets_all[is.na(Target), Target:=0]
  
  # Then further adjust the days, they should sum to one
  targets_all[TeleWorkLevel %in% telework_levels_teleworkdays, 
              Target := Target/sum(Target), 
              by = Occupation]
  targets_all[is.na(Target), Target:=0]
  
  # Get the labels consistent with those used in the models
  targets_all[, Occupation := c("mixed", "on-site","remote")[match(Occupation, occupations)]]
  targets_all[, TeleWorkLevel := c("WorkFromHome",
                                   "NoTelework",
                                   "1-3 days per month",
                                   "1 day per week",
                                   "2-3 days per week",
                                   "4 days per week",
                                   "5+ days per week")[match(TeleWorkLevel, telework_levels)]]
  
  targets_workfromhome <- targets_all[TeleWorkLevel %in% telework_levels_workfromhome]
  targets_telework <- targets_all[TeleWorkLevel %in% telework_levels_telework]
  targets_teleworkdays <- targets_all[!TeleWorkLevel %in% c(telework_levels_workfromhome, telework_levels_telework)]
  setnames(targets_teleworkdays, "TeleWorkLevel", "TeleWorkDays")
  
  # Worker Occupation
  # =================
  
  # shares of occupation type by location type
  occ_shares <- rbind(melt.data.table(occ_shares[,.(Azone, OnSite = PropRuralOnSite, 
                                                    Mixed = PropRuralMixed, Remote = PropRuralRemote)],
                                id.vars = c("Azone"), variable.name = "Occupation", 
                                value.name = "OccProp")[, LocType := "Rural"],
                      melt.data.table(occ_shares[,.(Azone, OnSite = PropTownOnSite, 
                                                    Mixed = PropTownMixed, Remote = PropTownRemote)],
                                      id.vars = c("Azone"), variable.name = "Occupation", 
                                      value.name = "OccProp")[, LocType := "Town"],
                      melt.data.table(occ_shares[,.(Azone, OnSite = PropMetroOnSite, 
                                                    Mixed = PropMetroMixed, Remote = PropMetroRemote)],
                                      id.vars = c("Azone"), variable.name = "Occupation", 
                                      value.name = "OccProp")[, LocType := "Urban"])

  occ_shares <- dcast.data.table(occ_shares, 
                                 Azone + LocType ~ Occupation,
                                 fun.aggregate = sum,
                                 value.var = "OccProp")
  
  occ_shares[, OnSite := OnSite/(OnSite + Mixed + Remote)]
  occ_shares[, Mixed := (OnSite + Mixed)/(OnSite + Mixed + Remote)]
  
  # add home zones to worker table and rename the work zones
  setnames(worker, c("Bzone", "Azone"), c("BzoneWork", "AzoneWork") )
  worker[hh, c("Bzone", "Azone") := .(i.Bzone, i.Azone), on = "HhId"]
  
  # add the work and home location types (occupation shares are by location type within azones)
  if("LocType" %in% colnames(bzone)){
    worker[bzone, LocType := i.LocType, on = "Bzone"]
    worker[bzone[, .(BzoneWork = Bzone, LocType)], LocTypeWork := i.LocType, on = "BzoneWork"]
  }
  if("LocType" %in% colnames(hh)){
    worker[hh, LocType := i.LocType, on = "HhId"]
  }
  
  # simulate the occupation for every worker by Azone and LocType
  worker[occ_shares, c("pOnSite", "pMixed") := .(i.OnSite, i.Mixed), on = c("Azone", "LocType")]
  worker[, draw_occ := runif(.N)]
  worker[, Occupation := ifelse(draw_occ < pOnSite,1, ifelse(draw_occ < pMixed,2,3))]
  worker[, Occupation := factor(Occupation, levels=c(1,2,3),labels = c("on-site", "mixed", "remote"))]
  
  # Do you work outside of the home?
  # ================================
  
  # Binary logit, usual work place is home or out of home (6.1%) of workers work from home
  # This model is conducted on the individual worker
  model_workfromhome <- loadPackageDataset("WorkFromHome_df")
  model_workfromhome <- data.table(model_workfromhome)
  
  # Worker Age
  worker[, WkrNum := as.integer(lapply(strsplit(WkrId, "-", fixed = TRUE),"[[",3))]
  worker_ages <- melt.data.table(hh[,.(HhId, Wkr15to19, Wkr20to29, Wkr30to54, Wkr55to64, Wkr65Plus)],
                                 id.vars = "HhId",
                                 variable.name = "WkrAge",
                                 value.name = "NumWkr")
  worker_ages <- worker_ages[NumWkr > 0]
  worker_ages <- worker_ages[rep(1:.N, NumWkr)][,WkrNum := 1:.N, by = HhId]
  worker[worker_ages, WkrAge := i.WkrAge, on = c("HhId", "WkrNum")]
  
  # Group Income
  hh[, IncGrp := c("IncomeUnder25", "Income25to50", "Income50to75", "Income75to100", "IncomeOver100")[findInterval(Income, c(0, 25000, 50000, 75000, 100000))]]
  worker[hh, IncGrp := i.IncGrp, on = "HhId"]
  
  # Household structure variable
  # LifeCycle is not quite the same
  #01: one adult, no children
  #02: 2+ adults, no children
  #03: one adult, children (corresponds to NHTS 03, 05, and 07)
  #04: 2+ adults, children (corresponds to NHTS 04, 06, and 08)
  #09: one adult, retired, no children
  #10: 2+ adults, retired, no children
  
  hh[as.integer(LifeCycle) %in% 1:4, LifeCycleWFH := c("SingleNoKids", "CoupleNoKids", "SingleKids5to15", "CoupleKids5to15")[as.integer(LifeCycle)]]
  hh[!is.na(LifeCycleWFH), LifeCycleWFH := ifelse(LifeCycleWFH == "SingleKids5to15" & Age0to14 == 0 & Age15to19 > 0, "SingleKidsOver15", LifeCycleWFH)]
  hh[!is.na(LifeCycleWFH), LifeCycleWFH := ifelse(LifeCycleWFH == "CoupleKids5to15" & Age0to14 == 0 & Age15to19 > 0, "CoupleKidsOver15", LifeCycleWFH)]
  
  worker[hh, LifeCycleWFH := i.LifeCycleWFH, on = "HhId"]
  
  # Add D1C, units of jobs/acre
  worker[bzone, D1C := i.D1C, on = "Bzone"]
  
  # Apply the model and iteratively adjust to match the targets
  worker[, Constant := 0]
  iter_max <- 5
  
  for(iter in 1:iter_max){
  
    # Apply the model with zero constants first and then iterate and update the constant
    # binary logit, estimated constant on the WorkFromHomeNo alternative, all other coefficients on the WorkFromHomeYes alternative
    
    # WorkFromHomeNo constant
    worker[, uWorkFromHomeNo := model_workfromhome[Variable == "Constant"]$Estimate]
    
    # categorical variables
    worker[, uWkrAge := model_workfromhome[Variable == "WkrAge"]$Estimate[match(WkrAge, model_workfromhome[Variable == "WkrAge"]$Level)]]
    worker[, uIncGrp := model_workfromhome[Variable == "IncGrp"]$Estimate[match(IncGrp, model_workfromhome[Variable == "IncGrp"]$Level)]]
    worker[, uLifeCycleWFH := model_workfromhome[Variable == "LifeCycleWFH"]$Estimate[match(LifeCycleWFH, model_workfromhome[Variable == "LifeCycleWFH"]$Level)]]
    worker[, uOccupation := model_workfromhome[Variable == "Occupation"]$Estimate[match(Occupation, model_workfromhome[Variable == "Occupation"]$Level)]]
    
    # continuous variables
    worker[, uD1C := model_workfromhome[Variable == "D1C"]$Estimate * D1C]
    
    # sum utility for WorkFromHomeYes alternative
    # include the target calibration constant on the yes alternative
    worker[, uWorkFromHomeYes := uWkrAge + uIncGrp + uLifeCycleWFH + uOccupation + uD1C + Constant]
    
    # calculate shares for Yes and No and then simulate
    worker[, pWorkFromHomeYes := exp(uWorkFromHomeYes)/(exp(uWorkFromHomeYes) + exp(uWorkFromHomeNo))]
    worker[, draw_wfh := runif(.N)]
    worker[, WorkFromHome := ifelse(draw_wfh < pWorkFromHomeYes, "Yes", "No")]
    
    # Compare the model and targets  
    workfromhome_shares <-  worker[,.(Num = .N), 
                                   keyby = .(WorkFromHome, Occupation)]
    
    workfromhome_shares[ , Model := Num/sum(Num, na.rm = TRUE), 
                         by = Occupation]
    
    workfromhome_shares[targets_workfromhome, 
                        Target := i.Target, 
                        on = "Occupation"]
    
    workfromhome_shares[WorkFromHome == "No", 
                        Target := 1 - Target]
    
    if (iter < iter_max){    
    
      # Calcuate the adjustment    
      workfromhome_shares[, ConstantAdj := log(Target/Model)]
      
      # Move the constant adjustment to the "yes" alternative
      workfromhome_shares[workfromhome_shares[WorkFromHome == "No"], 
                          ConstantAdj := ConstantAdj - i.ConstantAdj, 
                          on = "Occupation"]
      
      # update the constants in the worker table
      worker[workfromhome_shares[WorkFromHome == "Yes"], 
             Constant := Constant + i.ConstantAdj, 
             on = "Occupation"]
      
    }
    
  }
  
  worker[, Constant := NULL]
  
  # Do you Telework at all? 
  # ======================= 
  
  #  Binary logit. If the person does not work from home, do they telecommute at all during the week? (0 vs 1+)
  model_telework <- loadPackageDataset("Telework_df")
  model_telework <- data.table(model_telework)
  
  # Additional variables not in the work from home model
  # Commute Distance
  if(!"DistanceToWork" %in% colnames(worker)){
    DistToWork_ls <- loadPackageDataset("DistToWork_ls")
    
    # Names of the table in the list is the home location (county and loc type combination)
    # Column name is the work location
    # convert to data.table and changes all names to upper case
    DistToWork_ls_names <- names(DistToWork_ls)
    DistToWork_ls <- lapply(1:length(DistToWork_ls), function(x) data.table(DistToWork_ls[[x]]))
    names(DistToWork_ls) <- toupper(DistToWork_ls_names)
    lapply(DistToWork_ls, function(x) {setnames(x, toupper); invisible()})
    
    # household locations and worker locations
    worker[, AZ_LTH := toupper(paste(Azone, LocType, sep = "_"))]
    worker[, AZ_LTW := toupper(paste(AzoneWork, LocTypeWork, sep = "_"))]
    
    # Deal with some differences for out of state:
    # Distance to work matrices names for out of state geographies do not include the loctype
    # Distance to work matrices out of state geographies only out of state to in state direction
    # No out of state to out of state distance (allow for missing combinations in code).
    worker[grepl("OUTOFSTATE", AZ_LTH), AZ_LTH := toupper(Azone)]
    worker[grepl("OUTOFSTATE", AZ_LTW), c("AZ_LTH", "AZ_LTW") := .(toupper(AzoneWork), AZ_LTH)]
    
    # loop through the groups by origin and then destination and draw from the distribution
    for(azlth in unique(worker$AZ_LTH)){
      for(azltw in unique(worker[AZ_LTH == azlth]$AZ_LTW)){
        if(azltw %in% names(DistToWork_ls[[azlth]])){
          prob_vec <- unlist(DistToWork_ls[[azlth]][,azltw, with = FALSE])
        } else {
          prob_vec <- c(0, rep(0.1,10),rep(0,90))    
        }
        if(length(prob_vec[is.na(prob_vec)])>0) prob_vec <- c(0, rep(0.1,10),rep(0,90))
        worker[AZ_LTH == azlth & AZ_LTW == azltw, 
               CommuteDistanceBin := sample(101, 
                                            size = .N, 
                                            replace = TRUE, 
                                            prob = prob_vec)]
      }
    }
    
    # Draw a value to change from integer bin value, which represents the upper bound commute distance, 
    # Round max value to 100
    worker[, CommuteDistance := CommuteDistanceBin - runif(.N)]
    worker[, CommuteDistance := ifelse(CommuteDistance > 100, 100, CommuteDistance)]
  } else {
    worker[, CommuteDistance := DistanceToWork]
  }
  
  # for workers from home, replace commute distance with 0
  worker[WorkFromHome == "Yes", CommuteDistance := 0]
  
  # D1B
  # Add D1B, units of (persons/acre)
  worker[bzone, D1B := i.D1B, on = "Bzone"]
  
  # Apply the model and iteratively adjust to match the targets
  worker[, Constant := 0]
  iter_max <- 5
  
  for(iter in 1:iter_max){
    # Apply the model with zero constants first and then iterate and update the constant
    
    # binary logit, constant on the TeleWorkNo alternative, all other coefficients on the TeleWorkYes alternative
    # constant
    # include the target calibration constant on the yes alternative
    worker[WorkFromHome == "No", uTeleWorkNo := model_telework[Variable == "Constant"]$Estimate]
    worker[WorkFromHome == "No", uTeleWorkNo := uTeleWorkNo + Constant]
    worker[WorkFromHome == "No", uTeleWorkNo := pmin(uTeleWorkNo,700)]
    
    # categorical variables
    worker[WorkFromHome == "No", uTWY_WkrAge := model_telework[Variable == "WkrAge"]$Estimate[match(WkrAge, model_telework[Variable == "WkrAge"]$Level)]]
    worker[WorkFromHome == "No", uTWY_IncGrp := model_telework[Variable == "IncGrp"]$Estimate[match(IncGrp, model_telework[Variable == "IncGrp"]$Level)]]
    worker[WorkFromHome == "No", uTWY_LifeCycleWFH := model_telework[Variable == "LifeCycleWFH"]$Estimate[match(LifeCycleWFH, model_telework[Variable == "LifeCycleWFH"]$Level)]]
    worker[WorkFromHome == "No", uTWY_Occupation := model_telework[Variable == "Occupation"]$Estimate[match(Occupation, model_telework[Variable == "Occupation"]$Level)]]
    
    # continuous variables
    worker[WorkFromHome == "No", uTWY_CommuteDistance := model_telework[Variable == "CommuteDistance"]$Estimate * CommuteDistance]
    worker[WorkFromHome == "No", uTWY_D1B := model_telework[Variable == "D1B"]$Estimate * D1B]
    worker[WorkFromHome == "No", uTWY_D1C := model_telework[Variable == "D1C"]$Estimate * D1C]
    
    # sum utility for TeleWorkYes alternative
    worker[WorkFromHome == "No", uTeleWorkYes := uTWY_WkrAge + uTWY_IncGrp + uTWY_LifeCycleWFH + uTWY_Occupation + uTWY_CommuteDistance + uTWY_D1B + uTWY_D1C]
    worker[WorkFromHome == "No", uTeleWorkYes := pmin(uTeleWorkYes,700)] #yields inf values if taking exponent
    
    # calculate shares for Yes and No and then simulate
    worker[WorkFromHome == "No", pTeleWorkYes := exp(uTeleWorkYes)/(exp(uTeleWorkYes) + exp(uTeleWorkNo))]
    worker[WorkFromHome == "No", draw_tw := runif(.N)]
    worker[WorkFromHome == "No", TeleWork := ifelse(draw_tw < pTeleWorkYes, "Yes", "No")]
    
    # Compare the model and targets
    telework_shares <-  worker[WorkFromHome == "No",.(Num = .N), 
                               keyby = .(TeleWork, Occupation)]
    
    telework_shares[ , Model := Num/sum(Num, na.rm = TRUE), 
                     by = Occupation]
    
    telework_shares[targets_telework, 
                    Target := i.Target, 
                    on = "Occupation"]
    
    telework_shares[TeleWork == "Yes", 
                    Target := 1 - Target]
    
    if (iter < iter_max){    
      
      # Calcuate the adjustment  
      telework_shares[, ConstantAdj := log(Target/Model)]
      
      # Move the constant adjustment to the "no" alternative
      telework_shares[telework_shares[TeleWork == "Yes"], 
                      ConstantAdj := ConstantAdj - i.ConstantAdj, 
                      on = "Occupation"]
      
      # update the constants in the worker table
      worker[telework_shares[TeleWork == "No"], 
             Constant := Constant + i.ConstantAdj, 
             on = "Occupation"]
      
    }
    
  }
  
  worker[, Constant := NULL]
  
  # How many days teleworking
  # =========================
  
  # Ordered logit – for those who telework, how many days?  This model is applied on each worker in the HH. 
  model_telework_days <- loadPackageDataset("TeleworkDays_df")
  model_telework_days <- data.table(model_telework_days)
  
  # Apply the model and iteratively adjust to match the targets
  # No constant all alt 4
  worker[, paste0("Constant",0:3) := 0]
  iter_max <- 5
  
  for(iter in 1:iter_max){
    
    # Apply the model with zero constants first and then iterate and update the constant
    # ordered logit model
    # Choice 0  (1-3 days per month)
    # Choice 1 (1 day per week)
    # Choice 2 (2-3 days per week)
    # Choice 3 (4 days per week)
    # Choice 4 (5+ days per week)
    
    # constants
    worker[TeleWork == "Yes", uTeleWorkDays0 := model_telework_days[Level == "Threshold0"]$Estimate]
    worker[TeleWork == "Yes", uTeleWorkDays1 := model_telework_days[Level == "Threshold1"]$Estimate]
    worker[TeleWork == "Yes", uTeleWorkDays2 := model_telework_days[Level == "Threshold2"]$Estimate]
    worker[TeleWork == "Yes", uTeleWorkDays3 := model_telework_days[Level == "Threshold3"]$Estimate]
    
    # categorical variables
    worker[TeleWork == "Yes", uTWD_WkrAge := model_telework_days[Variable == "WkrAge"]$Estimate[match(WkrAge, model_telework[Variable == "WkrAge"]$Level)]]
    worker[TeleWork == "Yes", uTWD_IncGrp := model_telework_days[Variable == "IncGrp"]$Estimate[match(IncGrp, model_telework[Variable == "IncGrp"]$Level)]]
    worker[TeleWork == "Yes", uTWD_LifeCycleWFH := model_telework_days[Variable == "LifeCycleWFH"]$Estimate[match(LifeCycleWFH, model_telework[Variable == "LifeCycleWFH"]$Level)]]
    worker[TeleWork == "Yes", uTWD_Occupation := model_telework_days[Variable == "Occupation"]$Estimate[match(Occupation, model_telework[Variable == "Occupation"]$Level)]]
    
    # continuous variables
    worker[TeleWork == "Yes", uTWD_CommuteDistance := model_telework_days[Variable == "CommuteDistance"]$Estimate * CommuteDistance]
    
    # sum utility for TeleWorkDays4 alternative
    worker[TeleWork == "Yes", uTeleWorkDays4 := uTWD_WkrAge + uTWD_IncGrp + uTWD_LifeCycleWFH + uTWD_Occupation + uTWD_CommuteDistance]
    
    # Add the constant adjustments for matching targets
    worker[TeleWork == "Yes", uTeleWorkDays0 := uTeleWorkDays0 + Constant0]
    worker[TeleWork == "Yes", uTeleWorkDays1 := uTeleWorkDays1 + Constant1]
    worker[TeleWork == "Yes", uTeleWorkDays2 := uTeleWorkDays2 + Constant2]
    worker[TeleWork == "Yes", uTeleWorkDays3 := uTeleWorkDays3 + Constant3]
    
    # calculate shares for Alts 0-4 (in terms of at least that choice per ordered logit application method) and then simulate
    worker[TeleWork == "Yes", pTeleWorkDays1 := exp(uTeleWorkDays4)/(exp(uTeleWorkDays4) + exp(uTeleWorkDays0))]
    worker[TeleWork == "Yes", pTeleWorkDays2 := exp(uTeleWorkDays4)/(exp(uTeleWorkDays4) + exp(uTeleWorkDays1))]
    worker[TeleWork == "Yes", pTeleWorkDays3 := exp(uTeleWorkDays4)/(exp(uTeleWorkDays4) + exp(uTeleWorkDays2))]
    worker[TeleWork == "Yes", pTeleWorkDays4 := exp(uTeleWorkDays4)/(exp(uTeleWorkDays4) + exp(uTeleWorkDays3))]
    worker[TeleWork == "Yes", draw_twd := runif(.N)]
    worker[TeleWork == "Yes", TeleWorkDays := ifelse(draw_twd < pTeleWorkDays4, "5+ days per week",
                                                     ifelse(draw_twd < pTeleWorkDays3, "4 days per week",
                                                            ifelse(draw_twd < pTeleWorkDays2, "2-3 days per week",
                                                                   ifelse(draw_twd < pTeleWorkDays1, "1 day per week", "1-3 days per month"))))]
    
    worker[, TeleWorkDays := factor(TeleWorkDays, 
                                    levels = c("1-3 days per month",
                                               "1 day per week",
                                               "2-3 days per week",
                                               "4 days per week",
                                               "5+ days per week"),
                                    ordered = TRUE)]
    
    # Compare the model and targets  
    teleworkdays_shares <-  worker[TeleWork == "Yes",.(Num = .N), 
                                   keyby = .(TeleWorkDays, Occupation)]
    
    teleworkdays_shares[ , Model := Num/sum(Num, na.rm = TRUE), 
                         by = Occupation]
    
    teleworkdays_shares[targets_teleworkdays, 
                        Target := i.Target, 
                        on = c("Occupation", "TeleWorkDays")]
    
    # Ordered logit model is applied in terms of cumulative probalities and as a series of binary
    # choices at the threshold. Need to organize the comparison and constant adjustments i the same way
    teleworkdays_shares[, ModelCum := 1 - cumsum(Model), by = Occupation]
    teleworkdays_shares[, TargetCum := 1 - cumsum(Target), by = Occupation]
    
    if (iter < iter_max){    
      # Calcuate the adjustment    
      teleworkdays_shares[, ConstantAdjNeg :=  -log(TargetCum/ModelCum)]
      teleworkdays_shares[, ConstantAdjPos :=  log((1-TargetCum)/(1-ModelCum))]
      teleworkdays_shares[, ConstantAdj :=  ConstantAdjNeg + ConstantAdjPos]
      
      # update the constants in the worker table
      worker[teleworkdays_shares[TeleWorkDays == "1-3 days per month"], 
             Constant0 := Constant0 + i.ConstantAdj, 
             on = c("Occupation")]
      worker[teleworkdays_shares[TeleWorkDays == "1 day per week"], 
             Constant1 := Constant1 + i.ConstantAdj, 
             on = c("Occupation")]
      worker[teleworkdays_shares[TeleWorkDays == "2-3 days per week"], 
             Constant2 := Constant2 + i.ConstantAdj, 
             on = c("Occupation")]
      worker[teleworkdays_shares[TeleWorkDays == "4 days per week"], 
             Constant3 := Constant3 + i.ConstantAdj, 
             on = c("Occupation")]
      
    }
    
  }
  
  # Calculate variables for adjustment to VMT model:
  # ================================================
  #    - fraction of days telecommuted by worker and at the household level, 
  #    - Fraction workers work at home or telework 
  
  # Calculate telework days fraction, weighting each level of teleworkdays
  worker[, TeleWorkDaysFraction := c(0.1, 0.2, 0.5, 0.8, 1.0)[TeleWorkDays]]
  worker[, TeleWorkDaysFraction := ifelse(TeleWork == "No" | WorkFromHome == "Yes", 0, TeleWorkDaysFraction)]
  worker[, WorkFromHomeFraction := ifelse(WorkFromHome == "Yes", 1, TeleWorkDaysFraction)]
  
  # Calculate commute distance adjust for teleworking (one way commute distance * (1 - TeleWorkDaysFraction))
  worker[, CommuteDistanceAdj := CommuteDistance * (1 - TeleWorkDaysFraction)]
  
  # Household aggregration:
  hh[worker[,.(CommuteDistanceAdj = sum(CommuteDistanceAdj, na.rm = TRUE),
               FractionWorkersAtHome = sum(WorkFromHomeFraction, na.rm = TRUE)/.N),
            by = HhId],
     c("CommuteDistanceAdj", "FractionWorkersAtHome") := .(i.CommuteDistanceAdj, i.FractionWorkersAtHome),
     on = "HhId"]
  
  hh[is.na(CommuteDistanceAdj), CommuteDistanceAdj := 0]
  hh[is.na(FractionWorkersAtHome), FractionWorkersAtHome := 0]
  
  setkey(worker, WkrId)
  setkey(hh, HhId)
  
  worker[is.na(CommuteDistance), CommuteDistance := 0]
  worker[is.na(CommuteDistanceAdj), CommuteDistanceAdj := 0]
  
  # Build results list
  Out_ls <- initDataList()
  Out_ls$Year$Worker <-
    list(
      Occupation =  worker$Occupation,
      WorkFromHome = worker$WorkFromHome,
      TeleWork = worker$TeleWork,
      TeleWorkDays = worker$TeleWorkDays,
      WorkFromHomeFraction = worker$WorkFromHomeFraction,
      CommuteDistance = worker$CommuteDistance,
      CommuteDistanceAdj = worker$CommuteDistanceAdj
    )


  Out_ls$Year$Household <-
    list(
      FractionWorkersAtHome = hh$FractionWorkersAtHome,
      CommuteDistanceAdj = hh$CommuteDistanceAdj
    )

  
  #Return the list
  Out_ls
}

#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
#visioneval::documentModule("PredictWFH")

#====================
#SECTION 5: TEST CODE
#====================
# model test code is in tests/scripts/test.R
