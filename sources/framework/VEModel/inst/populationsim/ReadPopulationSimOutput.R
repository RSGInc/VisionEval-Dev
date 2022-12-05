#Main module function that reads PopulationSim output
#------------------------------------------------------
#' Main module function to reads PopulationSim output
#'
#' \code{ReadPopulationSimOutput} reads and stores the synthetic households and
#' persons produced by running PopulationSim in the VisionEval framework.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module along with:
#' LENGTH: A named integer vector having a single named element, "Household",
#' which identifies the length (number of rows) of the Household table to be
#' created in the datastore.
#' SIZE: A named integer vector having two elements. The first element, "Azone",
#' identifies the size of the longest Azone name. The second element, "HhId",
#' identifies the size of the longest HhId.
#' @import visioneval data.table
#' @name ReadPopulationSimOutput
#' @export
ReadPopulationSimOutput <- function(L){
  #fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Define dimension name vectors
  Az <- as.vector(unique(L$G$Geo_df$Azone))
  Ag_ <- c("Age0to14", "Age15to19", "Age20to29", "Age30to54", "Age55to64", "Age65Plus")
  Ages_ <- c(-0.1, 15, 20, 30, 55, 65, Inf)
  
  # Create Ouptut list
  Out_ls <- initDataList()
  
  syn_hh_dt <- as.data.table(L$Global$Household)
  syn_per_dt <- as.data.table(L$Global$Person)
  ve_geo_dt <- as.data.table(L$G$Geo_df)
  
  ve_hh_dt <- data.table(
    HhId = syn_hh_dt[, household_id],
    HhSize = syn_hh_dt[, NP],
    Workers = syn_hh_dt[,NW],
    Bzone = syn_hh_dt[, paste0("D", BG)],
    Azone = ve_geo_dt[,Azone][match(syn_hh_dt[,paste0("D", BG)], ve_geo_dt[,Bzone])],
    Marea = ve_geo_dt[,Marea][match(syn_hh_dt[,paste0("D", BG)], ve_geo_dt[,Bzone])],
    Income = syn_hh_dt[,HHINCADJ]
  )
  
  ve_hh_dt[, HhId:=paste0(Azone, "-", HhId)]
  
  ve_per_dt <- data.table(
    PerId = syn_per_dt[,paste0(household_id, "-", per_num)],
    HhId = syn_per_dt[, household_id],
    Age = syn_per_dt[, AGEP],
    Race = syn_per_dt[, RAC1P],
    Income = syn_per_dt[, PINCADJ],
    Worker = syn_per_dt[, WORKER],
    Bzone = syn_per_dt[, paste0("D", BG)],
    Azone = ve_geo_dt[,Azone][match(syn_per_dt[,paste0("D", BG)], ve_geo_dt[,Bzone])],
    Marea = ve_geo_dt[,Marea][match(syn_per_dt[,paste0("D", BG)], ve_geo_dt[,Bzone])]
  )
  
  ve_per_dt[, HhId:=paste0(Azone, "-", HhId)]
  ve_per_dt[, PerId:=paste0(Azone, "-", PerId)]
  
  # Find Age Group
  ve_per_dt[,AgeGrp:=cut(Age, Ages_, labels=Ag_, include.lowest=FALSE)]
  
  age_dt <- dcast.data.table(ve_per_dt, HhId~AgeGrp,fun.aggregate = length)
  ve_hh_dt <- age_dt[ve_hh_dt,on=.(HhId)]
  
  # Household Type
  hhtype_dt <- age_dt[,.(HhId, HhType=apply(.SD,1,paste0,collapse="-")),
                      .SDcols=!"HhId"]
  ve_hh_dt <- hhtype_dt[ve_hh_dt,on=.(HhId)]
  
  # Find Worker in age group
  wrk_dt <- dcast.data.table(ve_per_dt, HhId~AgeGrp, value.var = "Worker",
                             fun.aggregate = sum)
  setnames(wrk_dt, gsub("Age", "Wkr", names(wrk_dt)))
  wrk_dt[,Wkr0to14:=NULL]
  ve_hh_dt <- wrk_dt[ve_hh_dt,on=.(HhId)]
  
  # Azone summaries
  azone_dt <- ve_hh_dt[,.(
    NumHh=.N,
    NumGq=0,
    NumWkr=sum(Workers)
  ),keyby=.(Azone)]
  
  # Create output list
  # Azone list
  Out_ls$Year$Azone <- list(
    NumHh = azone_dt[.(Az), NumHh],
    NumGq = azone_dt[.(Az), NumGq],
    NumWkr = azone_dt[.(Az), NumWkr]
  )
  # Household list
  Out_ls$Year$Household <- as.list(ve_hh_dt)
  
  # Person list
  ve_per_dt[,AgeGrp:=NULL]
  Out_ls$Year$Person <- as.list(ve_per_dt)
  
  #Calculate LENGTH attribute for Household table
  attributes(Out_ls$Year$Household)$LENGTH <-
    length(Out_ls$Year$Household$HhId)
  #Calculate SIZE attributes for 'Household$Azone' and 'Household$HhId'
  attributes(Out_ls$Year$Household$Azone)$SIZE <-
    max(nchar(Out_ls$Year$Household$Azone))
  attributes(Out_ls$Year$Household$Bzone)$SIZE <-
    max(nchar(Out_ls$Year$Household$Bzone))
  attributes(Out_ls$Year$Household$Marea)$SIZE <-
    max(nchar(Out_ls$Year$Household$Marea))
  attributes(Out_ls$Year$Household$HhId)$SIZE <-
    max(nchar(Out_ls$Year$Household$HhId))
  attributes(Out_ls$Year$Household$HhType)$SIZE <-
    max(nchar(Out_ls$Year$Household$HhType))
  
  #Calculate LENGTH attribute for Person table
  attributes(Out_ls$Year$Person)$LENGTH <-
    length(Out_ls$Year$Person$PerId)
  #Calculate SIZE attributes for 'Person$Azone' and 'Person$HhId'
  attributes(Out_ls$Year$Person$Azone)$SIZE <-
    max(nchar(Out_ls$Year$Person$Azone))
  attributes(Out_ls$Year$Person$Bzone)$SIZE <-
    max(nchar(Out_ls$Year$Person$Bzone))
  attributes(Out_ls$Year$Person$Marea)$SIZE <-
    max(nchar(Out_ls$Year$Person$Marea))
  attributes(Out_ls$Year$Person$HhId)$SIZE <-
    max(nchar(Out_ls$Year$Person$HhId))
  attributes(Out_ls$Year$Person$PerId)$SIZE <-
    max(nchar(Out_ls$Year$Person$PerId))
  #Return the list
  Out_ls
}
