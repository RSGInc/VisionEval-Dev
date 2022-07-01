library(sf)
library(here)
library(data.table)
library(tidycensus)

# Easier than changing the working directory
PATH = here()

# Gather our parameters
source(file.path(PATH, 'inst/dataprep_settings.R'))

# Get GEOID list
bg_list <- unique(read.csv(file.path(PATH, 'inst/dataprep_sources/',params$zone_list), colClasses="character")$GEOID)
tract_list <- unique(substr(bg_list, 0, 11))

# BLOCKGROUP
# B11016  HOUSEHOLD TYPE BY HOUSEHOLD SIZE
# B01003  TOTAL POPULATION
# B25007  TENURE BY AGE OF HOUSEHOLDER
# B19001  HOUSEHOLD INCOME IN THE PAST 12 MONTHS (IN 2020 INFLATION-ADJUSTED DOLLARS)
# B02001  RACE


# TRACT LEVEL
# B08202  HOUSEHOLD SIZE BY NUMBER OF WORKERS IN HOUSEHOLD
# B25024  UNITS IN STRUCTURE


# Fetch the table column variables
acs_vars <- data.table(load_variables('2020', 'acs5'))


#### BLOCK GROUPS ####

# Get the column labels
bg_vars <- list(
  hhsiz = acs_vars[grepl('B11016_',name), ],
  race  = acs_vars[grepl('B02001_',name), ],
  hhage = acs_vars[grepl('B25007_',name), ],
  hhinc = acs_vars[grepl('B19001_',name), ],
  pop = acs_vars[grepl('B01003_',name), ]
  )


# Drop the ones we don't need
drop_vars <- c('B11016_002', 'B11016_009',
               'B25007_002', 'B25007_012',
               'B02001_001', 'B02001_009', 'B02001_010',
               'B19001_001')

bg_vars <- lapply(bg_vars, function(x) x[!(name %in% drop_vars),])


# Column bins for aggregation
bg_bins <- list(
  totals = list(
    POPBASE = 'B01003_001',
    HHBASE = 'B11016_001'
  ),
  hhsiz_bins = list(
    HHSIZ1 = "B11016_010",
    HHSIZ2 = c("B11016_003", "B11016_011"),
    HHSIZ3 = c("B11016_004", "B11016_012"),
    HHSIZ4 = c("B11016_005", "B11016_006", "B11016_007", "B11016_008",
               "B11016_013", "B11016_014", "B11016_015", "B11016_016")
  ),
  hhage_bins = list(
    HHAGE1 = c("B25007_003", "B25007_013"),
    HHAGE2 = c("B25007_004", "B25007_005", "B25007_006", "B25007_014", "B25007_015", "B25007_016"),
    HHAGE3 = c("B25007_007", "B25007_008", "B25007_017", "B25007_018"),
    HHAGE4 = c("B25007_009", "B25007_010", "B25007_011",
               "B25007_019", "B25007_020", "B25007_021")
  ),
  hhrace_bins = list(
    HHWHT = "B02001_002",
    HHBLK = "B02001_003",
    HHNAT = "B02001_004",
    HHASN = "B02001_005",
    HHPAC = "B02001_006",
    HHOTH = "B02001_007",
    HHMUL = "B02001_008"
  ),
  hhinc_bins = list(
    HHINC1 = c("B19001_002", "B19001_003", "B19001_004"),
    HHINC2 = c("B19001_005", "B19001_006", "B19001_007", "B19001_008", "B19001_009"),
    HHINC3 = c("B19001_010", "B19001_011", "B19001_012"),
    HHINC4 = c("B19001_013", "B19001_014", "B19001_015", "B19001_016", "B19001_017")
  )
)

# Fetch data
bg_vars_vec <- unlist(sapply(bg_vars, function(x) x$name), use.names = F)

bg_raw <- data.table(
  get_acs(geography = 'block group',
          year=2020,
          state=41,
          variables = bg_vars_vec, 
          cache_table = T)
)


# Select the GEOIDs
bg_raw <- bg_raw[GEOID %in% bg_list]

# Aggregate & cleanup
bg_agg <- rbindlist(lapply(bg_bins, function(b) {
  rbindlist(lapply(names(b), function(x) {
    bg_raw[variable %in% b[[x]], .('value'=sum(estimate), 'label' = x), by = GEOID]
    }))
  }))

bg_data <- dcast(bg_agg, 
                 GEOID~label,
                 value.var = 'value'
                 )[,c('GEOID', unlist(sapply(bg_bins, names), use.names=F)), with=F]



#### TRACTS ####

# Get the column labels
tract_vars <- list(
  hhwrk = acs_vars[grepl('B08202',name), ],
  hhtyp = acs_vars[grepl('B25024',name), ],
  pop = acs_vars[grepl('B01003_',name), ]
)

# Drop the ones we don't need
drop_vars <- c('B08202_006', 'B08202_009', 'B08202_012', 'B25024_001')
tract_vars <- lapply(tract_vars, function(x) x[!(name %in% drop_vars),])

# Bins
tract_bins <- list(
  totals = list(
    POPBASE = 'B01003_001',
    HHBASE = 'B08202_001'
  ),
  hhwrk_bins = list(
    HHWRK0 = tract_vars$hhwrk[grepl('No workers', label), name],
    HHWRK1 = tract_vars$hhwrk[grepl('1 worker', label), name],
    HHWRK2 = tract_vars$hhwrk[grepl('2 workers', label), name],
    HHWRK3 = tract_vars$hhwrk[grepl('3 or more workers', label), name]
  ),
  hhtyp = list(
    SF = c('B25024_002', 'B25024_003'),
    DUP = c('B25024_004'),
    MF = paste0('B25024_00', 5:9),
    MH = c('B25024_010', 'B25024_011')
  )
)


# Fetch data
tract_vars_vec <- unlist(sapply(tract_vars, function(x) x$name), use.names = F)

tract_raw <- data.table(
  get_acs(geography = 'tract',
          year=2020,
          state=41,
          variables = tract_vars_vec,
          cache_table = T)
)

# Select the GEOIDs
tract_raw <- tract_raw[GEOID %in% tract_list]

# Aggregate & cleanup
tract_agg <- rbindlist(lapply(tract_bins, function(b) {
  rbindlist(lapply(names(b), function(x) {
    tract_raw[variable %in% b[[x]], .('value'=sum(estimate), 'label' = x), by = GEOID]
  }))
}))

tract_data <- dcast(tract_agg, 
                 GEOID~label,
                 value.var = 'value'
                 )[,c('GEOID', unlist(sapply(tract_bins, names), use.names=F)), with=F]


#### GEO CROSSWALK & ADDITIONAL ZONE NAMES ####
# Calculate centroids - If we want
get_centroids <- function(geo) {
  centroids <- st_centroid(geo$geometry)
  coords <- data.table(st_coordinates(centroids))
  coords <- setNames(coords, c('Longitude', 'Latitude'))[, .(Latitude, Longitude)]
  
  latlon <- data.table(Geo=geo$GEOID, Year='2010', coords)
  latlon <- latlon[Geo %in% unique(xwalk$TAZID),]
  latlon[ , Geo := paste0('AMATS', Geo)]
  latlon[match(bzones, Geo),]
  return(latlon)
}


# Tract to PUMAS
t2p <- fread(file.path(PATH, 'inst/dataprep_sources', params$pumaxwalk), colClasses = 'character')

# Read geography file
tf <- tempfile()
unzip(file.path(PATH, 'inst/dataprep_sources', params$geography), exdir=tf)
geo <- st_read(file.path(tf, paste0(sub('\\..*$', '', params$geography), '.shp')))
unlink(tf)

# Get basic elements
geo_cross_walk <- data.table(geo)[, c('STATEFP', 'COUNTYFP',
                                      'TRACTCE', 'BLKGRPCE', 
                                      'GEOID')]

geo_cross_walk <- merge(geo_cross_walk, t2p)
geo_cross_walk[ , TRACTGEOID := paste0(STATEFP, COUNTYFP, TRACTCE)]

setnames(geo_cross_walk,'PUMA5CE' ,'PUMA')
setnames(tract_data,'GEOID','TRACTGEOID')


#### FINAL CONTROL TOTALS ###
# BG totals
control_totals_bg <- merge(bg_data, 
                           geo_cross_walk[ , .(GEOID, STATEFP, COUNTYFP, TRACTCE, TRACTGEOID, PUMA)],
                           by='GEOID')

# tract totals
control_totals_tract <- merge(tract_data, 
                           geo_cross_walk[ , .(STATEFP, COUNTYFP, TRACTCE, TRACTGEOID, PUMA)],
                           by='TRACTGEOID')


# SAVE OUTPUT
fwrite(geo_cross_walk, file.path(PATH, params$popsim_dir, 'data/geo_cross_walk.csv'))
fwrite(control_totals_bg, file.path(PATH, params$popsim_dir, 'data/control_totals_bg.csv'))
fwrite(control_totals_tract, file.path(PATH, params$popsim_dir, 'data/control_totals_tract.csv'))






