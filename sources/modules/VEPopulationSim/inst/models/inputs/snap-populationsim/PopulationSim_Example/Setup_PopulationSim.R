library(reticulate)
library(yaml)
library(xfun)
library(sf)
library(data.table)
library(tidycensus)
library(dplyr)
library(stringr)
library(ggplot2)
library(visioneval)

# Generic functions
append_root = function(path, root=VEModel::getRuntimeDirectory()) {
  if (!is_abs_path(path)) {
    file.path(root, path)
  } else {
    path
  } 
}
truncate_geoid = function(geoid, geography_type = 'block') {
  # geoid length
  geoid_len = c('block' = 15,
                'block group' = 12,
                'tract' = 11,
                'place' = 7,
                'county' = 5,
                'state' = 2)

  if (!geography_type %in% names(geoid_len)) {
    stop('Invalid geography type')
  }

  # Truncate string to select geometry
  return( substr(geoid, 0, geoid_len[geography_type]) )
}

# Function to fetch & format ACS totals using tidycensus
fetch_acsdata = function(autocfg, bg_list, popsimexampledir) {
  # BLOCKGROUP
  # B11016  HOUSEHOLD TYPE BY HOUSEHOLD SIZE
  # B01003  TOTAL POPULATION
  # B25007  TENURE BY AGE OF HOUSEHOLDER
  # B19001  HOUSEHOLD INCOME IN THE PAST 12 MONTHS (IN 2020 INFLATION-ADJUSTED DOLLARS)
  # B02001  RACE
  
  
  # TRACT LEVEL
  # B08202  HOUSEHOLD SIZE BY NUMBER OF WORKERS IN HOUSEHOLD
  # B25024  UNITS IN STRUCTURE
  
  
  # YEAR=2017
  # STATE=41 # Oregon
  
  if ('CENSUS_KEY' %in% names(autocfg)) {
    CENSUS_KEY = autocfg$CENSUS_KEY
  } else {
    CENSUS_KEY = NULL
  }
  
  # Census API Key: https://walker-data.com/tidycensus/reference/census_api_key.html
  if ( !('CENSUS_API_KEY' %in% names(Sys.getenv())) & is.null(CENSUS_KEY)) {
    stop('Need to either specify a Census API key or had it stored in your R environment!')
  }
  
  if ( !('CENSUS_API_KEY' %in% names(Sys.getenv())) & !is.null(CENSUS_KEY) ) { 
    #readRenviron(file.path(PATH, '.key'))
    census_api_key(CENSUS_KEY, overwrite = FALSE, install = FALSE)
  }
  
  # Check parameters
  stopifnot(is.numeric(autocfg$ACS_YEAR))
  stopifnot(!is.null(autocfg$ACS_YEAR))
  YEAR = autocfg$ACS_YEAR
  STATE = autocfg$STATE
  
  # Convert
  if( is.character(STATE) ) {
    if( nchar(STATE) > 2 ) {
      STATE = state.abb[grep(str_to_title(STATE), state.name)]    # Get state abbreviation
    }
    stopifnot(nchar(STATE)==2)
  }
  
  # Fetch the table column variables
  acs_vars = data.table(load_variables(YEAR, 'acs5'))
  acs_variables <- fread(file.path(popsimexampledir,
                                   autocfg$SOURCE_DATA$CENSUS$ACS_VARS[["FILE"]]))
  
  bg_vars_vec <- unique(acs_variables[toupper(geography)=="BLOCKGROUP",
                                      acs_var])
  tract_vars_vec <- unique(acs_variables[toupper(geography)=="TRACT",
                                         acs_var])
  
  
  # #### BLOCK GROUPS ####
  # 
  # # Get the column labels
  # bg_vars = list(
  #   hhsiz = acs_vars[grepl('B11016_',name), ],
  #   race  = acs_vars[grepl('B02001_',name), ],
  #   # hhage = acs_vars[grepl('B25007_',name), ],
  #   page = acs_vars[grepl('B01001_',name), ],
  #   hhinc = acs_vars[grepl('B19001_',name), ],
  #   pinc = acs_vars[grepl('B19301_001',name), ],
  #   pop = acs_vars[grepl('B01003_',name), ]
  # )
  # 
  # 
  # # Drop the ones we don't need
  # drop_vars = c('B11016_002', 'B11016_009',
  #                'B25007_002', 'B25007_012',
  #                'B01001_001', 'B01001_002', 'B01001_026',
  #                'B02001_001', 'B02001_009', 'B02001_010',
  #                'B19001_001')
  # 
  # bg_vars = lapply(bg_vars, function(x) x[!(name %in% drop_vars),])
  # 
  # #### TRACTS ####
  # # Get the column labels
  # tract_vars = list(
  #   hhwrk = acs_vars[grepl('B08202',name), ],
  #   hhtyp = acs_vars[grepl('B25024',name), ],
  #   pop = acs_vars[grepl('B01003_',name), ]
  # )
  # 
  # # Drop the ones we don't need
  # drop_vars = c('B08202_006', 'B08202_009', 'B08202_012', 'B25024_001')
  # tract_vars = lapply(tract_vars, function(x) x[!(name %in% drop_vars),])
  # 

  
  # Fetch block groupdata
  # bg_vars_vec = unlist(sapply(bg_vars, function(x) x$name), use.names = F)
  
  bg_raw = data.table(
    get_acs(geography = 'block group',
            year=YEAR,
            state=STATE,
            variables = bg_vars_vec, 
            cache_table = T)
  )
  
  # Fetch tract data
  # tract_vars_vec = unlist(sapply(tract_vars, function(x) x$name), use.names = F)
  
  tract_raw = data.table(
    get_acs(geography = 'tract',
            year=YEAR,
            state=STATE,
            variables = tract_vars_vec,
            cache_table = T)
  )
  
  
  
  #### Cleanup and format data  ####
  
  # tract list
  tract_list = truncate_geoid(bg_list, 'tract')
  
  # Select the GEOIDs
  bg_data    = bg_raw[GEOID %in% bg_list]
  tract_data = tract_raw[GEOID %in% tract_list]
  
  # Column bins for aggregation
  # bg_bins = list(
  #   totals = list(# These don't get summed up
  #     POPBASE = 'B01003_001',
  #     HHBASE = 'B11016_001',
  #     PINC = 'B19301_001'
  #   ),
  #   hhsiz_bins = list(
  #     HHSIZ1 = "B11016_010",
  #     HHSIZ2 = c("B11016_003", "B11016_011"),
  #     HHSIZ3 = c("B11016_004", "B11016_012"),
  #     HHSIZ4 = c("B11016_005", "B11016_006", "B11016_007", "B11016_008",
  #                "B11016_013", "B11016_014", "B11016_015", "B11016_016")
  #   ),
  #   age_bins = list(
  #     PAGE0TO14 = c(paste0("B01001_",sprintf("%03d",3:5)), paste0("B01001_",sprintf("%03d",27:29))),
  #     PAGE15TO19 = c("B01001_006", "B01001_007", "B01001_030", "B01001_031"),
  #     PAGE20TO29 = c(paste0("B01001_",sprintf("%03d",8:11)), paste0("B01001_",sprintf("%03d",32:35))),
  #     PAGE30TO54 = c(paste0("B01001_",sprintf("%03d",12:16)), paste0("B01001_",sprintf("%03d",36:40))),
  #     PAGE55TO64 = c(paste0("B01001_",sprintf("%03d",17:19)), paste0("B01001_",sprintf("%03d",41:43))),
  #     PAGE65PLUS = c(paste0("B01001_",sprintf("%03d",20:25)), paste0("B01001_",sprintf("%03d",44:49)))
  #   ),
  #   # hhage_bins = list(
  #   #   HHAGE1 = c("B25007_003", "B25007_013"),
  #   #   HHAGE2 = c("B25007_004", "B25007_005", "B25007_006", "B25007_014", "B25007_015", "B25007_016"),
  #   #   HHAGE3 = c("B25007_007", "B25007_008", "B25007_017", "B25007_018"),
  #   #   HHAGE4 = c("B25007_009", "B25007_010", "B25007_011",
  #   #              "B25007_019", "B25007_020", "B25007_021")
  #   # ),
  #   hhrace_bins = list(
  #     PRACWHT = "B02001_002",
  #     PRACBLK = "B02001_003",
  #     PRACNAT = "B02001_004",
  #     PRACASN = "B02001_005",
  #     PRACPAC = "B02001_006",
  #     PRACOTH = "B02001_007",
  #     PRACMUL = "B02001_008"
  #   ),
  #   hhinc_bins = list(
  #     HHINC1 = c("B19001_002", "B19001_003", "B19001_004"), #0to20K
  #     HHINC2 = c("B19001_005", "B19001_006", "B19001_007", "B19001_008"), #20to40K
  #     HHINC3 = c("B19001_009", "B19001_010", "B19001_011"), #40Kto60K
  #     HHINC4 = c("B19001_012"), #60Kto80K
  #     HHINC5 = c("B19001_013"),#80Kto100K
  #     HHINC6 = c("B19001_014", "B19001_015", "B19001_016", "B19001_017") #100KPlus
  #   )
  # )
  # # Bins
  # tract_bins = list(
  #   totals = list(
  #     POPBASE = 'B01003_001',
  #     HHBASE = 'B08202_001'
  #   ),
  #   hhwrk_bins = list(
  #     HHWRK0 = tract_vars$hhwrk[grepl('No workers', label), name],
  #     HHWRK1 = tract_vars$hhwrk[grepl('1 worker', label), name],
  #     HHWRK2 = tract_vars$hhwrk[grepl('2 workers', label), name],
  #     HHWRK3 = tract_vars$hhwrk[grepl('3 or more workers', label), name]
  #   ),
  #   hhtyp = list(
  #     SF = c('B25024_002', 'B25024_003'),
  #     DUP = c('B25024_004'),
  #     MF = paste0('B25024_00', 5:9),
  #     MH = c('B25024_010', 'B25024_011')
  #   )
  # )
  setkey(acs_variables, geography, acs_var)
  bg_raw[,popsim_var:=acs_variables[.("Blockgroup", variable), popsim_var]]
  tract_raw[,popsim_var:=acs_variables[.("Tract", variable), popsim_var]]
  
  # Aggregate & cleanup block groups
  # bg_agg = rbindlist(lapply(bg_bins, function(b) {
  #   rbindlist(lapply(names(b), function(x) {
  #     bg_raw[variable %in% b[[x]], .('value'=sum(estimate), 'label' = x), by = GEOID]
  #   }))
  # }))
  bg_raw[is.na(estimate), estimate:=0]
  bg_data = dcast(bg_raw, 
                  GEOID~popsim_var,
                  value.var = 'estimate',
                  fun.aggregate=sum
                  )
  # [,c('GEOID', unlist(sapply(bg_bins, names), use.names=F)), with=F]
  # bg_data = dcast(bg_agg, 
  #                 GEOID~label,
  #                 value.var = 'value'
  # )[,c('GEOID', unlist(sapply(bg_bins, names), use.names=F)), with=F]
  
  # bg_data[ , TRACTGEOID := truncate_geoid(GEOID, 'tract')]
  
  
  # Aggregate & cleanup tracts
  # tract_agg = rbindlist(lapply(tract_bins, function(b) {
  #   rbindlist(lapply(names(b), function(x) {
  #     tract_raw[variable %in% b[[x]], .('value'=sum(estimate), 'label' = x), by = GEOID]
  #   }))
  # }))
  
  # tract_data = dcast(tract_agg, 
  #                    GEOID~label,
  #                    value.var = 'value'
  # )[,c('GEOID', unlist(sapply(tract_bins, names), use.names=F)), with=F]
  tract_raw[is.na(estimate), estimate:=0]
  tract_data = dcast(tract_raw, 
                  GEOID~popsim_var,
                  value.var = 'estimate',
                  fun.aggregate=sum
                  )
  
  # Name differentiation
  setnames(tract_data,'GEOID','TRACTGEOID')
  
  return(list('tract' = tract_data, 'bg' = bg_data))
  
}

# Function to fetch and format PUMS data using tidycensus
fetch_pumsdata = function(autocfg, popsimexampledir) {
  
  if ('CENSUS_KEY' %in% names(autocfg)) {
    CENSUS_KEY = autocfg$CENSUS_KEY
  } else {
    CENSUS_KEY = NULL
  }
  
  # Census API Key: https://walker-data.com/tidycensus/reference/census_api_key.html
  if ( !('CENSUS_API_KEY' %in% names(Sys.getenv())) & is.null(CENSUS_KEY)) {
    stop('Need to either specify a Census API key or had it stored in your R environment!')
  }
  
  if ( !('CENSUS_API_KEY' %in% names(Sys.getenv())) & !is.null(CENSUS_KEY) ) { 
    #readRenviron(file.path(PATH, '.key'))
    census_api_key(CENSUS_KEY, overwrite = FALSE, install = FALSE)
  }
  
  #### PUMS SEED ####
  YEAR = autocfg$ACS_YEAR
  STATE = autocfg$STATE
  
  # Read pums variable file
  pums_vars <- fread(file.path(popsimexampledir,
                               autocfg$SOURCE_DATA$CENSUS$PUMS_VARS[["FILE"]]))
  
  # Latest pums year
  # PUMS_YEAR = pums_variables %>% 
  #   mutate(year=as.integer(year)) %>%
  #   filter(year <= YEAR) %>% 
  #   select(year) %>% max()
  PUMS_YEAR <- autocfg$ACS_YEAR
  
  # use this to look for the vars we need
  # pums_vars = pums_variables %>% 
  #   filter(year == PUMS_YEAR, survey == "acs5") %>% 
  #   distinct(var_code, var_label, data_type, level)
  
  # list the vars we need
  pums_vars_vec = pums_vars$var_code
  # pums_vars_vec = c("SERIALNO", "PUMA", "ST", "WGTP", "PWGTP", "SPORDER",
  #                   "AGEP", "NP", "HINCP", "PINCP", "ADJINC", "TYPE",
  #                   "ESR", "RAC1P", "BLD") 
  
  #### Fetch the data
  pums_data_raw = data.table(get_pums(
    variables = pums_vars_vec,
    state = STATE,
    survey = "acs5",
    year = PUMS_YEAR
  ))
  
  #### Recodes
  # Not group quarters
  pums_data = pums_data_raw[TYPE == 1, ]
  
  # Age of reference person "head of household"
  pums_data = merge(pums_data, 
                    pums_data[SPORDER==1, .(AGEHOH=AGEP), by = SERIALNO],
                    all = T)
  
  # Adjusted income
  pums_data[ , HHINCADJ := HINCP * as.numeric(ADJINC)]
  pums_data[ , PINCADJ := PINCP * as.numeric(ADJINC)]
  pums_data[PINCADJ < 0, PINCADJ:= 0]
  # pums_data[HHINCADJ < 0, HHINCADJ := 0]
  
  # Race
  #pums_data[ , HHRAC := ifelse(uniqueN(RAC1P)>1,9,RAC1P), by = SERIALNO]
  
  # Number of workers
  work_codes = c(1,2,4,5)
  pums_data = merge(pums_data, 
                    pums_data[ESR %in% work_codes, .(NW=.N), by=SERIALNO],
                    all=T)
  pums_data[is.na(NW), NW := 0]
  
  # If person is a worker
  pums_data[,WORKER:=as.integer(ESR %in% work_codes)]
  
  # Housing type
  pums_data[BLD %in% sprintf("%02d",c(1,10)), HTYPE := "MH"]
  pums_data[BLD %in% sprintf("%02d",2:3), HTYPE := "SF"]
  pums_data[BLD %in% sprintf("%02d",4), HTYPE := "DUP"]
  pums_data[BLD %in% sprintf("%02d",5:9), HTYPE := "MF"]
  
  # dummy region
  pums_data$REGION = 1
  pums_data[ , HHNUM := .GRP, by = SERIALNO]
  
  return( pums_data )
}

# Function to calculate centroids (If we don't have bzone_lat_lon.csv)
get_centroids = function(geo) {
  centroids = st_centroid(geo$geometry)
  coords = data.table(st_coordinates(centroids))
  coords = setNames(coords, c('Longitude', 'Latitude'))[, .(Latitude, Longitude)]
  
  latlon = data.table(Geo=geo$GEOID, Year='2010', coords)
  latlon = latlon[Geo %in% unique(xwalk$TAZID),]
  latlon[ , Geo := paste0('AMATS', Geo)]
  latlon[match(bzones, Geo),]
  return(latlon)
}

# get census zones from bzones
bzones_latlon_to_census = function(SOURCE_DATA, how = 'centroid') {
  
  # 'how' = be 'centroid' or 'hull' which selects any zone within
  # the convex hull formed by the centroids
  
  # Get GEOID list
  bzone_latlon = unique(
    fread(SOURCE_DATA$BZONE_LATLON, colClasses="character", drop='Year')
  )
  
  # Read geography file
  tf = tempfile()
  unzip(SOURCE_DATA$GEOGRAPHY, exdir=tf)
  census_poly = st_read(file.path(tf, paste0(sub('\\..*$', '', basename(SOURCE_DATA$GEOGRAPHY)), '.shp')))
  unlink(tf)
  
  # Remove '10' and '20' from GEOID10 or GEOID20
  colnames(census_poly) = gsub('10|20', '', colnames(census_poly))
  
  # Get blocks that bzone_latlon are within
  bzone_latlon = st_as_sf(bzone_latlon, coords = c("Longitude", "Latitude"), crs = 4326)
  bzone_latlon = st_transform(bzone_latlon, crs=st_crs(census_poly$geometry))
  
  # Convert to single geometric shape
  # this prevents sparse points from missing census zones
  bzone_hull = st_convex_hull(st_union(bzone_latlon))
  bzone_hull = st_transform(bzone_hull, crs=st_crs(census_poly$geometry))
  
  if (how == 'hull') {
    # Get census tracts in the region
    selection = st_intersection(census_poly, bzone_hull)
    census_bzone = census_poly[census_poly$GEOID %in% selection$GEOID,]
  }
  if (how == 'centroid') {
    selection = st_within(bzone_latlon, census_poly$geometry)
    census_bzone = census_poly[as.numeric(selection),]
    census_bzone$BzoneID = bzone_latlon$Geo
  }
  

  ggplot() + 
    geom_sf(data=census_bzone, aes(fill='GEOID')) +
    geom_sf(data=bzone_hull, alpha=0.5) +
    geom_sf(data=bzone_latlon) +
    theme_bw()
  
  
  return(census_bzone)

}

# get census zones from bzones
bzones_to_census = function(SOURCE_DATA, use_geo, how = 'centroid', minAreaProp=.05) {
  
  # 'how' = be 'centroid' or 'hull' which selects any zone within
  # the convex hull formed by the centroids
  
  geo_file <- SOURCE_DATA[[use_geo]]
  is_poly <- FALSE
  # Get GEOID list
  if(grepl(".shp$", geo_file)){
    is_poly <- TRUE
    bzone_geo <- st_read(geo_file)
  } else if(grepl(".zip$", geo_file)){
    is_poly <- TRUE
    tf = tempfile()
    unzip(geo_file, exdir=tf)
    bzone_geo = st_read(file.path(tf, paste0(sub('\\..*$', '', basename(geo_file)), '.shp')))
    unlink(tf)
  } else {
    bzone_geo = unique(
      fread(geo_file, colClasses="character", drop='Year')
    )
    setnames(bzone_geo, "Geo", "BzoneID")
  }
  
  # Read geography file
  tf = tempfile()
  unzip(SOURCE_DATA$GEOGRAPHY, exdir=tf)
  census_poly = st_read(file.path(tf, paste0(sub('\\..*$', '', basename(SOURCE_DATA$GEOGRAPHY)), '.shp')))
  unlink(tf)
  
  # Remove '10' and '20' from GEOID10 or GEOID20
  colnames(census_poly) = gsub('10|20', '', colnames(census_poly))
  
  # Get blocks that bzone_latlon are within
  if(!is_poly) {
    bzone_geo = st_as_sf(bzone_geo, coords = c("Longitude", "Latitude"), crs = 4326)
  }
  bzone_geo = st_transform(bzone_geo, crs=st_crs(census_poly))
  
  # Convert to single geometric shape
  # this prevents sparse points from missing census zones
  # bzone_hull = st_convex_hull(st_union(bzone_geo))
  # bzone_hull = st_transform(bzone_hull, crs=st_crs(census_poly$geometry))
  
  # if (how == 'hull') {
  #   # Get census tracts in the region
  #   selection = st_intersection(census_poly, bzone_hull)
  #   census_bzone = census_poly[census_poly$GEOID %in% selection$GEOID,]
  # }
  # if (how == 'centroid') {
  #   selection = st_within(bzone_latlon, census_poly$geometry)
  #   census_bzone = census_poly[as.numeric(selection),]
  # }
  
  bzone_selection = st_intersection(bzone_geo[,c("BzoneID")], census_poly[,c("STATEFP","COUNTYFP","TRACTCE","BLKGRPCE","GEOID")])
  if(is_poly){
    bzone_selection[["Area"]] = as.numeric(st_area(bzone_selection))
    bzone_selection_dt <- data.table(st_set_geometry(bzone_selection, NULL))
    bzone_selection_dt[,PropArea:=Area/sum(Area),by=.(BzoneID)]
    bzone_selection_dt[,Keep:=.N==1,by=.(BzoneID)]
    bzone_selection_dt[Keep==FALSE & PropArea>minAreaProp, Keep:=TRUE]
    bzone_selection_dt[,Missing:=!any(Keep),by=.(BzoneID)]
    bzone_selection_dt[Missing==TRUE,.N]
    bzone_selection_dt <- bzone_selection_dt[Keep==TRUE][,c("Keep", "Missing"):=NULL][]
    # bzone_selection_dt[,PropArea:=Area/sum(Area),by=.(BzoneID)]
    bzone_selection_dt[,c("PropArea"):=NULL]
  } else {
    bzone_selection_dt <- data.table(st_set_geometry(bzone_selection, NULL))
    bzone_selection_dt[, Area:=1]
  }
  

  # ggplot() + 
  #   geom_sf(data=census_bzone, aes(fill='GEOID')) +
  #   geom_sf(data=bzone_hull, alpha=0.5) +
  #   geom_sf(data=bzone_latlon) +
  #   theme_bw()
  
  
  return(bzone_selection_dt)

}

# Main function to setup population sim
setup_populationsim = function(
    cfg_dir='../runtime/populationsim/popsim_settings.yaml'
    ) {
  
  # Read config yaml
  cfg = read_yaml(cfg_dir)
  
  # Setup python environment
  # # initialize conda env if not already done
  # if(!('popsimR' %in% conda_list()$name)) {
  #   conda_create(envname = 'popsimR',
  #                packages = 'pytables',
  #                python_version = '3.9')
  #   py_install('populationsim', envname = 'popsimR', pip=TRUE)
  # }
  
  # Setup the directory paths
  RUNTIME_DIR = VEModel::getRuntimeDirectory()
  MODEL_DIR = append_root(cfg$MODEL_DIR)
  POPSIM_EXAMPLE_DIR = file.path(MODEL_DIR, 
                                 "inputs", "snap-populationsim", "PopulationSim_Example")
  POPSIM_DIR = file.path(POPSIM_EXAMPLE_DIR, 
                         cfg$POPSIM_RUN_DIR)
  TEMPLATE_DIR = file.path(POPSIM_EXAMPLE_DIR, 
                           cfg$POPSIM_TEMPLATE_DIR)
  
  # Check source data validity
  CENSUS_SOURCE_DATA = lapply(names(cfg$AUTO_DATA_PREP$SOURCE_DATA$CENSUS), function(file_name) {
    FP = file.path(POPSIM_EXAMPLE_DIR,cfg$AUTO_DATA_PREP$SOURCE_DATA$CENSUS[[file_name]][["FILE"]])
    # FP = append_root(FP, RUNTIME_DIR)
    if (!file.exists(FP)) stop(paste("Can't find file for", file_name))
    return(FP)
  })
  names(CENSUS_SOURCE_DATA) = names(cfg$AUTO_DATA_PREP$SOURCE_DATA$CENSUS)
  
  MODEL_SOURCE_DATA = lapply(names(cfg$AUTO_DATA_PREP$SOURCE_DATA$MODEL), function(file_name) {
    FP = file.path(cfg$AUTO_DATA_PREP$SOURCE_DATA$MODEL[[file_name]][["FILE"]])
    FP = append_root(FP, MODEL_DIR)
    if (!file.exists(FP)) stop(paste("Can't find file for", file_name))
    return(FP)
  })
  names(MODEL_SOURCE_DATA) = names(cfg$AUTO_DATA_PREP$SOURCE_DATA$MODEL)
  SOURCE_DATA = c(CENSUS_SOURCE_DATA, MODEL_SOURCE_DATA)
  
  # Copy template to model directory
  if (dir.exists(POPSIM_DIR)) unlink(POPSIM_DIR, recursive = TRUE)
  dir.create(POPSIM_DIR)
  file.copy(from=TEMPLATE_DIR, to=POPSIM_DIR, recursive = TRUE)
  # success <- file.rename(file.path(POPSIM_DIR,'PopulationSim_Template'), POPSIM_DIR)
  # if(!success) stop("Failed creating populationsim setup. Duplicate copy may exists.")
  
  
  ### Automated data prep
  # Get list of GEOIDs that 
  census_bzone = bzones_to_census(SOURCE_DATA, cfg$AUTO_DATA_PREP$SOURCE_DATA$USE, how='centroid',
                                  minAreaProp = cfg$AUTO_DATA_PREP$SOURCE_DATA$CENSUS$BZONE_GEOGRAPHY$MINAREA)
  # census_bzone = bzones_to_census(SOURCE_DATA, how='centroid')
  census_bzone[,PropBGArea:=Area/sum(Area),.(GEOID)]
  census_bzone[,PropTractArea:=Area/sum(Area),.(TRACTCE)]
  # 
  # Tract to PUMAS
  puma_xwalk = fread(SOURCE_DATA$PUMA_XWALK, colClasses = 'character')

  # Get basic elements
  geo_xwalk = merge(data.table(census_bzone)[,.(BzoneID, STATEFP,COUNTYFP,TRACTCE,BLKGRPCE,GEOID, PropBGArea, PropTractArea, Area)],
                    puma_xwalk, on=.(STATEFP, COUNTYFP, TRACTCE))
  # geo_xwalk = merge(data.table(census_bzone)[,.(BzoneID, STATEFP,COUNTYFP,TRACTCE,BLKGRPCE,GEOID)],
  #                   puma_xwalk, on=.(STATEFP, COUNTYFP, TRACTCE))
  geo_xwalk[ , TRACTGEOID := truncate_geoid(GEOID, 'tract')]
  geo_xwalk[ , REGION := 1]
  setnames(geo_xwalk, 'PUMA5CE', "PUMA")
  geo_xwalk <- unique(geo_xwalk)
  # Only one Bzone in the crosswalk when writing into populationsim
  geo_xwalk[,Keep:=FALSE]
  geo_xwalk[,Keep:=Area==max(Area),.(BzoneID)]
  geo_xwalk[,MissTract:=!any(Keep),.(TRACTGEOID)]
  miss_tract <- geo_xwalk[MissTract==TRUE,TRACTGEOID]
  
  # Fetch PUMS data
  pums_data = fetch_pumsdata(cfg$AUTO_DATA_PREP, POPSIM_EXAMPLE_DIR)
  
  # Fetch ACS data
  acs_data = fetch_acsdata(cfg$AUTO_DATA_PREP, bg_list=unique(geo_xwalk$GEOID), 
                           POPSIM_EXAMPLE_DIR)
  bg_data = acs_data[['bg']]
  bg_data = bg_data[GEOID %in% unique(geo_xwalk$GEOID)]
  tract_data = acs_data[['tract']]
  tract_data = tract_data[TRACTGEOID %in% unique(geo_xwalk$TRACTGEOID)]
  if(length(miss_tract)) tract_data[!TRACTGEOID %in% miss_tract]
  
  # Match the controls
  
  round_sum <- function(x) diff(c(0, round(cumsum(x))))
  tract_data[,HHBASE:=round_sum(HHBASE*sum(bg_data$HHBASE)/sum(HHBASE))]
  tract_data[,POPBASE:=round_sum(POPBASE*sum(bg_data$POPBASE)/sum(POPBASE))]
  
  hh_names <- c("HHWRK0", "HHWRK1", "HHWRK2", "HHWRK3")
  tract_data[,c(hh_names):=.SD*HHBASE/pmax(rowSums(.SD),1),
             .SDcols=hh_names]
  tract_data[,c(hh_names):=data.table(apply(.SD,2,function(x) (round_sum(x)))),
             .SDcols=hh_names]
  hh_names <- c("SF", "DUP", "MF", "MH")
  tract_data[,c(hh_names):=.SD*HHBASE/pmax(rowSums(.SD),1),
             .SDcols=hh_names]
  tract_data[,c(hh_names):=data.table(apply(.SD,2,function(x) (round_sum(x)))),
             .SDcols=hh_names]
  
  #### FINAL PUMS SEED DATA ###
  # HH/PER vars
  pums_vars <- fread(file.path(POPSIM_EXAMPLE_DIR,
                               cfg$AUTO_DATA_PREP$SOURCE_DATA$CENSUS$PUMS_VARS))
  drop_vars <- c("ST", "HHINCP", "PINCP", "ADJINC", "TYPE", "BLD", "ESR")
  pums_vars_filtered <- pums_vars[!var_code %in% drop_vars]
  
  base_vars = union(c('SERIALNO', 'HHNUM', 'PUMA', 'REGION'), pums_vars_filtered[level=="",var_code])
  hh_vars = c(base_vars, 'NP', 'NW', 'HHINCADJ', 'WGTP', 'HTYPE', pums_vars_filtered[level=="housing",var_code])
  per_vars = c(base_vars, 'SPORDER', 'PWGTP', 'RAC1P', 'AGEP', 'PINCADJ', 'WORKER', pums_vars_filtered[level=="person",var_code])
  
  # Extract & format seed data
  seed_pums_hh = unique(pums_data[,hh_vars, with=F])
  seed_pums_per = pums_data[,per_vars, with=F]
  # deflators_dt <- fread(file.path(MODEL_DIR,cfg$AUTO_DATA_PREP$SOURCE_DATA$MODEL$DEFLATORS))
  # seed_pums_hh[,HHINCADJ:=round_sum(HHINCADJ*deflators_dt[``])]
  
  # seed_pums_hh[,HTYPE:=match(HTYPE, c("SF", "MF", "MH", "DUP"))]
  
  
  #### FINAL CONTROL TOTALS ####
  # BG totals
  control_totals_bzone = merge(
    geo_xwalk[,!'BLKGRPCE'], 
    bg_data,
    by='GEOID', all.x = TRUE)
  
  if(!"PropBGArea" %in% colnames(control_totals_bzone)) control_totals_bzone[,PropBGArea:=1/.N,.(GEOID)]
  if(!"PropTractArea" %in% colnames(control_totals_bzone)) control_totals_bzone[,PropTractArea:=1/.N,.(TRACTGEOID)]
  if(!"BzoneID" %in% colnames(control_totals_bzone)) control_totals_bzone[,BzoneID:=GEOID]
  geo_names <- c("GEOID", "STATEFP", "COUNTYFP", "TRACTCE", "BzoneID", "PUMA",
                 "TRACTGEOID", "REGION", "PropBGArea", "PropTractArea")
  control_totals_bzone[,c(setdiff(colnames(control_totals_bzone),
                                  geo_names)):= lapply(.SD, function(x) round_sum(x*PropBGArea)),
                       .SDcols=!c(intersect(geo_names,colnames(control_totals_bzone))),
                       by=.(GEOID)]
  control_totals_bzone = control_totals_bzone[,lapply(.SD,sum,na.rm=TRUE),
                                              .SDcols=!c(intersect(geo_names,colnames(control_totals_bzone))),
                                              by=.(BzoneID)]
  
  # tract totals
  # control_totals_tract = merge(
  #   unique(geo_xwalk[,!c('BLKGRPCE', 'GEOID')]),
  #   tract_data,
  #   by='TRACTGEOID')
  
  # control_totals_tract[,c(setdiff(colnames(control_totals_tract),
  #                                 geo_names)):= lapply(.SD, function(x) round_sum(x*PropTractArea)),
  #                      .SDcols=!c(intersect(geo_names, colnames(control_totals_tract))),
  #                      by=.(TRACTGEOID)]
  
  #### SCALED TOTALS ####
  
  # Trust blocks b/c tract might overlap outside of region
  scaled_control_totals_meta = colSums(tract_data[,!c("TRACTGEOID","POPBASE")])
  scaled_control_totals_meta = scaled_control_totals_meta * bg_data[,sum(POPBASE)] / tract_data[,sum(POPBASE)]
  scaled_control_totals_meta = round(scaled_control_totals_meta)
  
  # Add in the block totals
  scaled_control_totals_meta = as.data.table(t(
    c("REGION"=1,
      scaled_control_totals_meta[setdiff(names(scaled_control_totals_meta),
                                                      colnames(bg_data))], 
      colSums(bg_data[,!c("GEOID"), with=F])
      )
  ))
  
  
  ### CONFIRM GEOGRAPHY NAMES ####
  # setnames(geo_cross_walk, c('TRACTGEOID', 'GEOID'), c('TRACT', 'BG'))
  # setnames(control_totals_bg, c('TRACTGEOID', 'GEOID'), c('TRACT', 'BG'))
  # setnames(control_totals_tract, 'TRACTGEOID', 'TRACT')
  control_totals_bzone[,c(paste0("HHSIZ",1:4)):=.SD*HHBASE/pmax(rowSums(.SD),1),
                       .SDcols=paste0("HHSIZ", 1:4)]
  control_totals_bzone[,c(paste0("HHSIZ",1:4)):=data.table(apply(.SD,2,function(x) (round_sum(x)))),
                       .SDcols=paste0("HHSIZ", 1:4)]
  control_totals_bzone[,c(paste0("HHINC",1:6)):=.SD*HHBASE/pmax(rowSums(.SD),1),
                       .SDcols=paste0("HHINC", 1:6)]
  control_totals_bzone[,c(paste0("HHINC",1:6)):=data.table(apply(.SD,2,function(x) (round_sum(x)))),
                       .SDcols=paste0("HHINC", 1:6)]
  
  person_names <- c("PAGE0TO14", "PAGE15TO19", "PAGE20TO29", "PAGE30TO54", "PAGE55TO64","PAGE65PLUS" )
  control_totals_bzone[,c(person_names):=.SD*POPBASE/pmax(rowSums(.SD),1),
                       .SDcols=person_names]
  control_totals_bzone[,c(person_names):=data.table(apply(.SD,2,function(x) (round_sum(x)))),
                       .SDcols=person_names]
  
  person_names <- c("PRACWHT", "PRACBLK", "PRACNAT", "PRACASN", "PRACPAC","PRACOTH", "PRACMUL")
  control_totals_bzone[,c(person_names):=.SD*POPBASE/pmax(rowSums(.SD),1),
                       .SDcols=person_names]
  control_totals_bzone[,c(person_names):=data.table(apply(.SD,2,function(x) (round_sum(x)))),
                       .SDcols=person_names]
  
  # hh_names <- c("HHWRK0", "HHWRK1", "HHWRK2", "HHWRK3")
  # tract_data[,c(hh_names):=.SD*HHBASE/pmax(rowSums(.SD),1),
  #                      .SDcols=hh_names]
  # tract_data[,c(hh_names):=data.table(apply(.SD,2,function(x) (round_sum(x)))),
  #                      .SDcols=hh_names]
  # hh_names <- c("SF", "DUP", "MF", "MH")
  # tract_data[,c(hh_names):=.SD*HHBASE/pmax(rowSums(.SD),1),
  #                      .SDcols=hh_names]
  # tract_data[,c(hh_names):=data.table(apply(.SD,2,function(x) (round_sum(x)))),
  #                      .SDcols=hh_names]
  # 
  
  #### SAVE OUTPUT ####
  POPSIM_DIR <- file.path(POPSIM_DIR, "PopulationSim_Template")
  fwrite(unique(geo_xwalk[Keep==TRUE,.(BzoneID, PUMA, TRACTGEOID, REGION)]), file.path(POPSIM_DIR, 'data/geo_cross_walk.csv'))
  fwrite(control_totals_bzone, file.path(POPSIM_DIR, 'data/control_totals_bg.csv'))
  fwrite(tract_data, file.path(POPSIM_DIR, 'data/control_totals_tract.csv'))
  fwrite(seed_pums_hh, file.path(POPSIM_DIR, 'data/seed_households.csv'))
  fwrite(seed_pums_per, file.path(POPSIM_DIR, 'data/seed_persons.csv'))
  fwrite(scaled_control_totals_meta, file.path(POPSIM_DIR, 'data/scaled_control_totals_meta.csv'))
}


run_populationsim = function(cfg_dir='../runtime/populationsim/popsim_settings.yaml') {
  
  cfg = read_yaml(cfg_dir)
  RUNTIME_DIR = VEModel::getRuntimeDirectory()
  MODEL_DIR = append_root(cfg$MODEL_DIR)
  POPSIM_DIR = file.path(dirname(MODEL_DIR), paste0(basename(MODEL_DIR),'-populationsim'))
  
  if(!dir.exists(file.path(POPSIM_DIR,'output'))) {
    dir.create(file.path(POPSIM_DIR,'output'))
  }
  
  if(!('popsim' %in% conda_list()$name)) {
    conda_create(envname = 'popsim',
                 packages = 'pytables',
                 python_version = '3.9')
    py_install('populationsim', envname = 'popsim', pip=TRUE)
  }
  
  use_condaenv('popsim', required = TRUE)
  import('activitysim')
  
  command = sprintf('python %s/run_populationsim.py --working_dir %s', POPSIM_DIR, POPSIM_DIR)
  returncode <- system(command, wait=TRUE, invisible = FALSE)
  if(returncode==0) cat("PopulationSim successfully finisihed.")
  
}

create_specifications <- function(inp_dict_dt=NULL,
                                  set_dict_dt=NULL,
                                  ACSYear=2017,
                                  ModelYear=2010){
  
  if(is.null(inp_dict_dt)) stop("Missing popsim data dictionary")
  if(is.null(set_dict_dt)) stop("Missing vesimhh data dictionary")
  
  inp_dict_dt[,NAME:=paste0("\"", NAME,"\"")]
  inp_dict_dt[,FILE:=paste0("\"", FILE,"\"")]
  inp_dict_dt[,TABLE:=paste0("\"", TABLE,"\"")]
  inp_dict_dt[,TYPE:=paste0("\"", TYPE,"\"")]
  inp_dict_dt[,GROUP:=paste0("\"", GROUP,"\"")]
  inp_dict_dt[,UNITS:=paste0("\"", UNITS,"\"")]
  inp_dict_dt[,DESCRIPTION:=paste0("\"", DESCRIPTION,"\"")]
  inp_dict_dt[ISELEMENTOF=="",ISELEMENTOF:='"""']
  
  
  get_dict_dt <- copy(inp_dict_dt)
  get_dict_dt[TYPE=="\"currency\"", UNITS:=paste0(strtrim(UNITS,nchar(UNITS)-1),".", ACSYear,"\"")]
  
  set_dict_dt[,NAME:=paste0("\"", NAME,"\"")]
  set_dict_dt[,TABLE:=paste0("\"", TABLE,"\"")]
  set_dict_dt[,TYPE:=paste0("\"", TYPE,"\"")]
  set_dict_dt[,GROUP:=paste0("\"", GROUP,"\"")]
  set_dict_dt[,UNITS:=paste0("\"", UNITS,"\"")]
  set_dict_dt[,DESCRIPTION:=paste0("\"", DESCRIPTION,"\"")]
  set_dict_dt[ISELEMENTOF=="",ISELEMENTOF:='"""']
  
  
  
  
  create_items <- function(arr_, add_tabs=0, inp_type="Inp"){
    INP_REQD_NAMES <- c("FILE", "DESCRIPTION", "UNLIKELY", "TOTAL")
    SET_REQD_NAME <- c("DESCRIPTION")
    if(inp_type == "Get"){
      arr_ <- arr_[setdiff(names(arr_), INP_REQD_NAMES)]
    } else if(inp_type == "Set"){
      arr_ <- arr_[setdiff(names(arr_), setdiff(INP_REQD_NAMES, SET_REQD_NAME))]
    }
    arr_[grepl("\"\"", arr_)] <- gsub("\"\"", "\"",arr_[grepl("\"\"", arr_)])
    arr_[grepl("= \"\"", arr_)] <- gsub("\"\"", "",arr_[grepl("= \"\"", arr_)])
    arr_[is.na(arr_)] <- '""'
    arr_names <- names(arr_)
    max_arr_index <- length(arr_names)
    out_ <- paste0(paste0(rep("\t", add_tabs), collapse = ""), "items(\n")
    for(index in seq_along(arr_names)){
      arr_name <- arr_names[index]
      out_ <- paste0(out_, paste0(rep("\t", add_tabs+2), collapse = ""), arr_name," = ", arr_[arr_name])
      if(index < max_arr_index){
        out_ <- paste0(out_, ",\n")
      } else {
        out_ <- paste0(out_, "\n)")
      }
    }
    out_
  }
  
  
  specification_text <- "
ReadPopulationSimOutputSpecifications <- list(
  #Level of geography module is applied at
  RunBy = \"Region\",
  #Specify new tables to be created by Inp if any
  NewInpTable = items(
    item(
      TABLE = \"Household\",
      GROUP = \"Global\"
    ),
    item(
      TABLE = \"Person\",
      GROUP = \"Global\"
    )
  ),
  #Specify new tables to be created by Set if any
  NewSetTable = items(
    item(
      TABLE = \"Household\",
      GROUP = \"Year\"
    ),
    item(
      TABLE = \"Person\",
      GROUP = \"Year\"
    )
  ),
  #Specify input data
"
  
  # 
  specification_text <- paste0(specification_text,
                               "Inp = items(\n\t",
                               paste0(apply(inp_dict_dt,1,create_items), collapse = ",\n\t"),
                               "\n),\n",
                               "Get = items(\n\t",
                               paste0(apply(get_dict_dt,1,create_items,inp_type="Get"), collapse = ",\n\t"),
                               "\n),\n",
                               "Set = items(\n\t",
                               paste0(apply(set_dict_dt,1,create_items,inp_type="Set"), collapse = ",\n\t"),
                               "\n)\n)\n")
  eval(specification_text)
  
}

replace_values <- function(x, value="b"){
  x[x==value] <- as.character(NA)
  x
}

setup_vemodel <- function(cfg_dir='../runtime/populationsim/popsim_settings.yaml'){
  # Read config yaml
  cfg = read_yaml(cfg_dir)
  
  # Setup the directory paths
  RUNTIME_DIR = VEModel::getRuntimeDirectory()
  MODEL_DIR = append_root(cfg$MODEL_DIR)
  POPSIM_DIR = file.path(dirname(MODEL_DIR), paste0(basename(MODEL_DIR),'-populationsim'))
  
  basemodel <- openModel(MODEL_DIR)
  POPSIM_MODEL_NAME <- paste0(basemodel$modelName,"_populationsim")
  POPSIM_MODEL_NAME2 <- paste0(basemodel$modelName,"_populationsim_v2")
  if(dir.exists(file.path(dirname(MODEL_DIR), POPSIM_MODEL_NAME))) unlink(file.path(dirname(MODEL_DIR), POPSIM_MODEL_NAME),
                                                                          recursive = TRUE)
  popsimmodel <- basemodel$copy(newName = POPSIM_MODEL_NAME,copyResults = FALSE, 
                                copyArchives = FALSE, log = "warn")
  
  model_script_file <- file.path(popsimmodel$modelPath, popsimmodel$setting("ScriptsDir"),
                            popsimmodel$setting("ModelScript"))
  model_script <- readLines(model_script_file)
  runModuleLine <- grep("runModule", model_script, value = TRUE)
  runModuleLine <- runModuleLine[1]
  writeLines(runModuleLine, model_script_file)

  hh_dt <- fread(file.path(POPSIM_DIR, cfg$POPSIM_OUTPUTS$HOUSEHOLD$FILE), na.strings = "b")
  per_dt <- fread(file.path(POPSIM_DIR, cfg$POPSIM_OUTPUTS$PERSON$FILE), na.strings = "b")
  
  # hh_dt <- hh_dt[,lapply(.SD, replace_values)]
  # per_dt <- per_dt[,lapply(.SD, replace_values)]
  
  # Make sure that income is greater than 0
  for(inc_name in cfg$POPSIM_OUTPUTS$HOUSEHOLD$CURRENCY){
    hh_dt[get(inc_name) < 1, c(inc_name):=runif(.N)*10]
  }
  
  for(inc_name in cfg$POPSIM_OUTPUTS$PERSON$CURRENCY){
    per_dt[get(inc_name) < 1, c(inc_name):=runif(.N)*10]
  }
  
  setnames(hh_dt, cfg$POPSIM_OUTPUTS$HOUSEHOLD$CURRENCY, 
           paste0(cfg$POPSIM_OUTPUTS$HOUSEHOLD$CURRENCY, 
                  ".", cfg$AUTO_DATA_PREP$ACS_YEAR))
  setnames(per_dt, cfg$POPSIM_OUTPUTS$PERSON$CURRENCY, 
           paste0(cfg$POPSIM_OUTPUTS$PERSON$CURRENCY, 
                  ".", cfg$AUTO_DATA_PREP$ACS_YEAR))
  
  # Write it to the input file
  fwrite(hh_dt, file.path(popsimmodel$modelPath,
                          popsimmodel$RunParam_ls$InputDir, 
                          basename(cfg$POPSIM_OUTPUTS$HOUSEHOLD$FILE)))
  fwrite(per_dt, file.path(popsimmodel$modelPath,
                          popsimmodel$RunParam_ls$InputDir, 
                          basename(cfg$POPSIM_OUTPUTS$PERSON$FILE)))
  
  
  
  
  inp_spec <- fread(file.path(RUNTIME_DIR, 'populationsim',
                                  cfg$AUTO_DATA_PREP$SOURCE_DATA$DATA_DICTIONARY$POPSIM))
  set_spec <- fread(file.path(RUNTIME_DIR, 'populationsim',
                                  cfg$AUTO_DATA_PREP$SOURCE_DATA$DATA_DICTIONARY$VEHOUSEHOLD))
  model_spec <- create_specifications(inp_spec, set_spec,
                                      ACSYear = cfg$AUTO_DATA_PREP$ACS_YEAR,
                                      ModelYear = popsimmodel$RunParam_ls$Years[1])
  model_spec <- eval(parse(text = model_spec))

  ve.model <- visioneval::modelEnvironment(Clear="VEModelStage::run") # add Owner
  runPath <- popsimmodel$modelStages[[POPSIM_MODEL_NAME]][["RunPath"]]
  dir.create(runPath)
  owd <- setwd(runPath) # may not need inside a future
  on.exit(setwd(owd))
  
  RunStatus <- try (
    {
      # Initialize Log, create new ModelState
      ve.model$RunModel <- TRUE
      visioneval::initLog(Threshold=popsimmodel$log(), Save=TRUE, envir=ve.model) # Log stage
      invisible(visioneval::loadModel(popsimmodel$modelStages[[POPSIM_MODEL_NAME]][["RunParam_ls"]]))
      visioneval::setModelState()                       # Save ModelState.Rda
      visioneval::prepareModelRun()                     # Initialize Datastore
      
      # Run the model script
      AllSpecs_ls <- list(list(
        ModuleName = "ReadPopulationSimOutput",
        PackageName = "VEPopulationSim",
        RunFor = "Region",
        Specs_ls = processModuleSpecs(model_spec)
      ))
      processInputFiles(AllSpecs_ls)

      source("../../../populationsim/ReadPopulationSimOutput_CCRPC.R")
      # debugonce(ReadPopulationSimOutput)
      for(Year in popsimmodel$RunParam_ls$Years){
        invisible(runScript(ReadPopulationSimOutput,
                  processModuleSpecs(model_spec),
                  RunYear = Year,
                  writeDatastore = TRUE))
      }
      
      # Report completion into model log
      visioneval::writeLog("Model Run Complete",Level="warn")
      # Use the following RunStatus if we got this far without error
      # codeStatus("Run Complete")
      9
    },
    silent=TRUE
  )
  if(dir.exists(file.path(dirname(MODEL_DIR), POPSIM_MODEL_NAME2))) unlink(file.path(dirname(MODEL_DIR), POPSIM_MODEL_NAME2),
                                                                          recursive = TRUE)
  popsimmodel2 <- basemodel$copy(newName = POPSIM_MODEL_NAME2,copyResults = FALSE, 
                                copyArchives = FALSE, log = "warn")
  popsimmodel2_config_file <- file.path(popsimmodel2$modelPath, "visioneval.cnf")
  popsimmodel2_config <- read_yaml(popsimmodel2_config_file)
  popsimmodel2_config[["LoadModel"]] <- popsimmodel$modelPath
  write_yaml(popsimmodel2_config,popsimmodel2_config_file)
  popsimmodel2_runscripfile <- file.path(popsimmodel2$modelPath,
                                         popsimmodel2$setting("ScriptsDir"),
                                         popsimmodel2$setting("ModelScript"))
  run_script <- readLines(popsimmodel2_runscripfile)
  
  modules_to_skip <- c("CreateHouseholds", 
                       "PredictWorkers",
                       "PredictIncome")
  skip_lines <- as.vector(sapply(run_script, function(x) any(str_detect(x, pattern = modules_to_skip))))
  
  run_script <- run_script[!skip_lines]
  modules_to_change <- "LocateEmployment"
  change_lines <- as.vector(sapply(run_script, function(x) any(str_detect(x, pattern = modules_to_change))))
  run_script[change_lines] <- gsub("VELandUse", "VEPopulationSim",
                                   run_script[change_lines])
  
  writeLines(run_script, popsimmodel2_runscripfile)
  popsimmodel2$configure()
  popsimmodel2
}
