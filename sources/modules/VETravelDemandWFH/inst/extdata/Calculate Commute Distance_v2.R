library(data.table)
library(dplyr)
library(geosphere)
library(tidyr)
library(R.utils)
# library(osrm)

# #Code to download od data
# lodes <- 'https://lehd.ces.census.gov/data/lodes/LODES7/'
# state.abb <- 'ma'
# year <- '2015'
# 
# #Download in-state od
# temp <- tempfile()
# path <- paste0(lodes, state.abb, '/od/', state.abb, '_od_main_JT00_', year, '.csv.gz')
# download.file(path, temp)
# con <- gunzip(temp, paste0(state.abb, '_od_main_JT00_', year, '.csv'))
# unlink(temp)
# 
# # #Download out-of-state od
# temp <- tempfile()
# path <- paste0(lodes, state.abb, '/od/', state.abb, '_od_aux_JT00_', year, '.csv.gz')
# download.file(path, temp)
# con <- gunzip(temp, paste0(state.abb, '_od_aux_JT00_', year, '.csv'))
# unlink(temp)

#Read in Mass OD data, crosswalk, and area types
#Data from Census LEHD
statefips <- 25
MaOd <- fread('ma_od_main_JT00_2015.csv', colClasses = c('w_geocode'='character', 'h_geocode'='character'))
MaOdOutofState <- fread('ma_od_aux_JT00_2015.csv', colClasses = c('w_geocode'='character', 'h_geocode'='character'))
MaOd <- rbind(MaOd, MaOdOutofState)
Xwalk <- fread('us_xwalk.csv', colClasses = c('tabblk2010'='character', 'bgrp'='character'))
geo <- fread('geo.csv')
                                               
#Data exported from VESimLandUseData
#loadPackageDataset("SimLandUseData_df","VESimLandUseData")
SimLandUseData_df <- fread("SimLandUseData_df.csv", colClasses = c('GEOID10'='character'))

#Join OD data with block group geocodes for both home and work geoids
Xwalk <- select(Xwalk, tabblk2010, bgrp, blklatdd, blklondd, st, ctyname)
Xwalk$ctyname <- gsub(' County,.*', '', Xwalk$ctyname)
WorkBlockGroups <- Xwalk
colnames(WorkBlockGroups) <- c('w_geocode', 'w_bgrp', 'w_lat', 'w_lon', 'w_st', 'w_ctyname')
MaOd <- merge(x = MaOd, y = WorkBlockGroups, by = 'w_geocode', all.x = TRUE)
HomeBlockGroups <- Xwalk
colnames(HomeBlockGroups) <- c('h_geocode', 'h_bgrp', 'h_lat', 'h_lon', 'h_st', 'h_ctyname')
MaOd <- merge(x = MaOd, y = HomeBlockGroups, by = 'h_geocode', all.x = TRUE)
remove(Xwalk, WorkBlockGroups, HomeBlockGroups)

#Calculate travel distance
#Get rid of distant locations causing errors
MaOd <- subset(MaOd, h_lon > -90)
#Set home as origin and work as destination and calculate distance
origin <- cbind(MaOd$h_lat, MaOd$h_lon)
destination <- cbind(MaOd$w_lat, MaOd$w_lon)
MaOd$distance <- distHaversine(origin, destination, r = 3963.19)

#Alternative approach to calculate distance, getting error
# osrm <- osrmTable(
#   src = origin,
#   dst = destination)

#Create a rounded distance
MaOd$distancernd <- round(MaOd$distance)

#Join location types data
LocType <- select(SimLandUseData_df, GEOID10, LocType)
MaOd <- merge(x = MaOd, y = LocType, by.x = 'w_bgrp', by.y = 'GEOID10', all.x = TRUE)
names(MaOd)[names(MaOd) == 'LocType'] <- 'w_loctype'
MaOd <- merge(x = MaOd, y = LocType , by.x = 'h_bgrp', by.y = 'GEOID10', all.x = TRUE)
names(MaOd)[names(MaOd) == 'LocType'] <- 'h_loctype'

#Join Marea info
MaOd <- merge(x = MaOd, y = geo, by.x = 'w_ctyname', by.y = 'Azone', all.x = TRUE)

#Get work location type and county combinations
MaOd$w_ctyloctype <- paste0(MaOd$w_ctyname, '_', MaOd$w_loctype)

#Get home location type and county combinations
MaOd <- MaOd %>% drop_na(h_loctype)
MaOd <- MaOd %>% drop_na(w_loctype)
MaOd$h_ctyloctype[MaOd$h_st==statefips] <- paste0(MaOd$h_ctyname[MaOd$h_st==statefips], '_', MaOd$h_loctype[MaOd$h_st==25])
MaOd$h_ctyloctype[MaOd$h_st!=statefips] <- paste0(MaOd$Marea[MaOd$h_st!=statefips], 'OutofState')

#Create list with a commute distance distributions for every home and workplace area type
DistToWork_ls <- list()
HomeCtyLocType <- unique(MaOd$h_ctyloctype)
HomeCtyLocType <- HomeCtyLocType[HomeCtyLocType != 'NoneOutofState']
for (h in HomeCtyLocType) {
  #For every home area type count commute mileage by workplace area type
  DistWork <- subset(MaOd, h_ctyloctype == h) %>%
    select(distancernd, w_ctyloctype) %>%
    count(distancernd,  w_ctyloctype)
  DistWork <- spread(DistWork, key = 'w_ctyloctype', value = "n")
  #Create new dataframe that has rows that match the max distance to work
  maxdist <- max(DistWork$distancernd)
  DistWorkMax <- data.frame(matrix(ncol = ncol(DistWork), nrow = maxdist + 1))
  rownames(DistWorkMax) <- 0:(nrow(DistWorkMax)-1)
  colnames(DistWorkMax) <- colnames(DistWork)
  for (i in 0:nrow(DistWorkMax)) {
    if (i %in% DistWork$distancernd) {
    DistWorkMax[as.character(i), ] <- DistWork[which(DistWork$distancernd == i), ]
    }
  }
  DistWorkMax <- subset(DistWorkMax, select = -(distancernd))
  DistWorkMax[is.na(DistWorkMax)] <- 0
  #Create a max commute distance of 100 miles
  DistWorkMax[101, ] <- colSums(DistWorkMax[101:nrow(DistWorkMax), ])
  DistWorkMax <- DistWorkMax[0:101, ]
  #Find commute probabilities by work place area type
  DistWorkMax <- prop.table(as.matrix(DistWorkMax), margin = 2)
  DistWorkMax <- as.data.frame(DistWorkMax)
  DistWorkMax <- DistWorkMax[, order(names(DistWorkMax))]
  DistToWork_ls <- append(DistToWork_ls, list(DistWorkMax))
}
DistToWork_ls <- setNames(DistToWork_ls, HomeCtyLocType)
save(DistToWork_ls, file = "DistToWork_ls.Rda")

