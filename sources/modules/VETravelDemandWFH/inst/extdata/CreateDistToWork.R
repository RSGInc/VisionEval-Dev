library(data.table)

ModuleDir <- "sources/modules/VETravelDemandWFH/"
CurDir <- setwd(ModuleDir)
on.exit(setwd(CurDir))

FileName <- "Telework_Distances.csv"
FileDir <- "inst/extdata"
FilePath <- file.path(FileDir, FileName)

# Read distance file
DistanceDist_dt <- fread(FilePath)

# Example Data
# DistanceDist_dt <- structure(list(Home_Utype = c("C-Baker", "C-Clackamas", "C-Clatsop", 
# "C-Columbia", "C-Coos", "C-Crook"), Work_Utype = c("C-Baker", 
# "C-Baker", "C-Baker", "C-Baker", "C-Baker", "C-Baker"), TeleType = c("Mixed", 
# "Mixed", "Mixed", "Mixed", "Mixed", "Mixed"), Year = c(2010L, 
# 2010L, 2010L, 2010L, 2010L, 2010L), Workers = c(593L, 0L, 0L, 
# 0L, 0L, 0L), Distance1 = c(282L, 0L, 0L, 0L, 0L, 0L), Distance2 = c(249L, 
# 0L, 0L, 0L, 0L, 0L), Distance3 = c(62L, 0L, 0L, 0L, 0L, 0L), 
#     Distance4 = c(0L, 0L, 0L, 0L, 0L, 0L), Distance5 = c(0L, 
#     0L, 0L, 0L, 0L, 0L), Distance6 = c(0L, 0L, 0L, 0L, 0L, 0L
#     ), Distance7 = c(0L, 0L, 0L, 0L, 0L, 0L), Distance8 = c(0L, 
#     0L, 0L, 0L, 0L, 0L), Distance9 = c(0L, 0L, 0L, 0L, 0L, 0L
#     ), Distance10 = c(0L, 0L, 0L, 0L, 0L, 0L), Distance11 = c(0L, 
#     0L, 0L, 0L, 0L, 0L), Distance12 = c(0L, 0L, 0L, 0L, 0L, 0L
#     ), Distance13 = c(0L, 0L, 0L, 0L, 0L, 0L), Distance14 = c(0L, 
#     0L, 0L, 0L, 0L, 0L), Distance15 = c(0L, 0L, 0L, 0L, 0L, 0L
#     ), Distance16 = c(0L, 0L, 0L, 0L, 0L, 0L), Distance17 = c(0L, 
#     0L, 0L, 0L, 0L, 0L), Distance18 = c(0L, 0L, 0L, 0L, 0L, 0L
#     ), Distance19 = c(0L, 0L, 0L, 0L, 0L, 0L), Distance20 = c(0L, 
#     0L, 0L, 0L, 0L, 0L), Distance21 = c(0L, 0L, 0L, 0L, 0L, 0L
#     ), Distance22 = c(0L, 0L, 0L, 0L, 0L, 0L), Distance23 = c(0L, 
#     0L, 0L, 0L, 0L, 0L), Distance24 = c(0L, 0L, 0L, 0L, 0L, 0L
#     ), Distance25 = c(0L, 0L, 0L, 0L, 0L, 0L), Distance26 = c(0L, 
#     0L, 0L, 0L, 0L, 0L), Distance27 = c(0L, 0L, 0L, 0L, 0L, 0L
#     ), Distance28 = c(0L, 0L, 0L, 0L, 0L, 0L), Distance29 = c(0L, 
#     0L, 0L, 0L, 0L, 0L), Distance30 = c(0L, 0L, 0L, 0L, 0L, 0L
#     ), Distance35 = c(0L, 0L, 0L, 0L, 0L, 0L), Distance40 = c(0L, 
#     0L, 0L, 0L, 0L, 0L), Distance45 = c(0L, 0L, 0L, 0L, 0L, 0L
#     ), Distance50 = c(0L, 0L, 0L, 0L, 0L, 0L), Distance60 = c(0L, 
#     0L, 0L, 0L, 0L, 0L), Distance70 = c(0L, 0L, 0L, 0L, 0L, 0L
#     ), Distance80 = c(0L, 0L, 0L, 0L, 0L, 0L), Distance90 = c(0L, 
#     0L, 0L, 0L, 0L, 0L), Distance100 = c(0L, 0L, 0L, 0L, 0L, 
#     0L), Distance150 = c(0L, 0L, 0L, 0L, 0L, 0L), Distance200 = c(0L, 
#     0L, 0L, 0L, 0L, 0L), Distance1000 = c(0L, 0L, 0L, 0L, 0L, 
#     0L)), row.names = c(NA, -6L), class = c("data.table", "data.frame"
# ))

DistanceDist_dt[,c("HUType","Home"):=tstrsplit(Home_Utype,"-")]
DistanceDist_dt[,c("WUType","Work"):=tstrsplit(Work_Utype,"-")]

UType <- c("U"="Urban", "C"="Town", "R"="Rural")

DistanceDist_dt[,HUType:=UType[HUType]]
DistanceDist_dt[,WUType:=UType[WUType]]

DistanceVarNames <- grep("Distance", colnames(DistanceDist_dt),
                         ignore.case = TRUE, value = TRUE)

DistanceDist_dt <- DistanceDist_dt[Year==2010]
DistanceDist_dt <- DistanceDist_dt

roundSum <- function(x){
  diff(c(0,round(cumsum(x))))
}


createTripDistbyDitance <- function(trip_dt, work_vars, dist_vars){
  trip_long_dt <- melt.data.table(trip_dt, id.vars=work_vars, measure.vars = dist_vars,
                                  variable.name="DistLabels",
                                  value.name = "NumTrips")
  # trip_long_dt <- trip_long_dt[NumTrips > 0]
  dcast_formula <- paste0("... ~ ", paste0(work_vars, collapse = " + "))
  trip_wide_dt <- dcast.data.table(trip_long_dt, as.formula(dcast_formula),
                                   value.var = "NumTrips",
                                   fun.aggregate = sum)
  trip_wide_dt[,Distance:=as.integer(gsub("Distance","",DistLabels))]
  setorder(trip_wide_dt,Distance)
  trip_wide_dt[,DistBin:=1]
  trip_wide_dt[Distance>30 & Distance <=50, DistBin:=5]
  trip_wide_dt[Distance>50 & Distance <=100, DistBin:=10]
  trip_wide_dt <- trip_wide_dt[trip_wide_dt[,rep(.I,DistBin)]]
  keep_names <- c("DistLabels", "Distance", "DistBin")
  oth_names <- setdiff(colnames(trip_wide_dt), keep_names)
  positive_trips <- unlist(trip_wide_dt[,lapply(.SD,sum),.SDcols=oth_names])
  positive_trips <- positive_trips[positive_trips>0]
  oth_names <- names(positive_trips)
  trip_wide_dt[,c(oth_names):=lapply(.SD,function(x) x/DistBin),.SDcols=oth_names]
  trip_wide_dt[DistBin>1,c(oth_names):=lapply(.SD, roundSum),.SDcols=oth_names,
               by=.(Distance,DistBin)]
  trip_wide_dt[,Distance:=.I-1]
  trip_wide_dt[Distance>=100,Distance:=100]
  trip_wide_dt[Distance==100,c(oth_names):=lapply(.SD, sum),.SDcols=oth_names]
  trip_wide_dt <- trip_wide_dt[1:101]
  trip_wide_dt[,c(oth_names):=lapply(.SD, function(x) x/max(sum(x),1)),.SDcols=oth_names]
  DistToWork_df <- as.data.frame(trip_wide_dt[,.SD,.SDcols=oth_names])
  rownames(DistToWork_df) <- trip_wide_dt$Distance
  DistToWork_df
}

remove_names <- c("Home_Utype", "Work_Utype", "TeleType", "Year", "Workers")
DistanceToWork_dt <- DistanceDist_dt[,.(list(createTripDistbyDitance(.SD, 
                                                                     work_vars = c("Work", "WUType"),
                                                                     dist_vars = DistanceVarNames))),
                .SDcols=!c(remove_names, "Home", "HUType"),
                by=.(Home,HUType)]
DistToWork_ls <- DistanceToWork_dt$V1
names(DistToWork_ls) <- paste0(DistanceToWork_dt$Home,"_",DistanceToWork_dt$HUType)
visioneval::savePackageDataset(DistToWork_ls)



