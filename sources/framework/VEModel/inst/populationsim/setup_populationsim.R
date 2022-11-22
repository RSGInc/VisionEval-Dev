library(reticulate)
library(yaml)
library(xfun)
library(sf)
library(data.table)
library(tidycensus)
library(dplyr)
library(stringr)
library(ggplot2)
library(reticulate)

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
fetch_acsdata = function(autocfg, bg_list) {
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
    census_api_key(KEY, overwrite = FALSE, install = FALSE)
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
  
  
  #### BLOCK GROUPS ####
  
  # Get the column labels
  bg_vars = list(
    hhsiz = acs_vars[grepl('B11016_',name), ],
    race  = acs_vars[grepl('B02001_',name), ],
    # hhage = acs_vars[grepl('B25007_',name), ],
    page = acs_vars[grepl('B01001_',name), ],
    hhinc = acs_vars[grepl('B19001_',name), ],
    pinc = acs_vars[grepl('B19301_001',name), ],
    pop = acs_vars[grepl('B01003_',name), ]
  )
  
  
  # Drop the ones we don't need
  drop_vars = c('B11016_002', 'B11016_009',
                 'B25007_002', 'B25007_012',
                 'B01001_001', 'B01001_002', 'B01001_026',
                 'B02001_001', 'B02001_009', 'B02001_010',
                 'B19001_001')
  
  bg_vars = lapply(bg_vars, function(x) x[!(name %in% drop_vars),])
  
  #### TRACTS ####
  # Get the column labels
  tract_vars = list(
    hhwrk = acs_vars[grepl('B08202',name), ],
    hhtyp = acs_vars[grepl('B25024',name), ],
    pop = acs_vars[grepl('B01003_',name), ]
  )
  
  # Drop the ones we don't need
  drop_vars = c('B08202_006', 'B08202_009', 'B08202_012', 'B25024_001')
  tract_vars = lapply(tract_vars, function(x) x[!(name %in% drop_vars),])
  

  
  # Fetch block groupdata
  bg_vars_vec = unlist(sapply(bg_vars, function(x) x$name), use.names = F)
  
  bg_raw = data.table(
    get_acs(geography = 'block group',
            year=YEAR,
            state=STATE,
            variables = bg_vars_vec, 
            cache_table = T)
  )
  
  # Fetch tract data
  tract_vars_vec = unlist(sapply(tract_vars, function(x) x$name), use.names = F)
  
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
  bg_bins = list(
    totals = list(# These don't get summed up
      POPBASE = 'B01003_001',
      HHBASE = 'B11016_001',
      PINC = 'B19301_001'
    ),
    hhsiz_bins = list(
      HHSIZ1 = "B11016_010",
      HHSIZ2 = c("B11016_003", "B11016_011"),
      HHSIZ3 = c("B11016_004", "B11016_012"),
      HHSIZ4 = c("B11016_005", "B11016_006", "B11016_007", "B11016_008",
                 "B11016_013", "B11016_014", "B11016_015", "B11016_016")
    ),
    age_bins = list(
      PAGE0TO14 = c(paste0("B01001_",sprintf("%03d",3:5)), paste0("B01001_",sprintf("%03d",27:29))),
      PAGE15TO19 = c("B01001_006", "B01001_007", "B01001_030", "B01001_031"),
      PAGE20TO29 = c(paste0("B01001_",sprintf("%03d",8:11)), paste0("B01001_",sprintf("%03d",32:35))),
      PAGE30TO54 = c(paste0("B01001_",sprintf("%03d",12:16)), paste0("B01001_",sprintf("%03d",36:40))),
      PAGE55TO64 = c(paste0("B01001_",sprintf("%03d",17:19)), paste0("B01001_",sprintf("%03d",41:43))),
      PAGE65PLUS = c(paste0("B01001_",sprintf("%03d",20:25)), paste0("B01001_",sprintf("%03d",44:49)))
    ),
    # hhage_bins = list(
    #   HHAGE1 = c("B25007_003", "B25007_013"),
    #   HHAGE2 = c("B25007_004", "B25007_005", "B25007_006", "B25007_014", "B25007_015", "B25007_016"),
    #   HHAGE3 = c("B25007_007", "B25007_008", "B25007_017", "B25007_018"),
    #   HHAGE4 = c("B25007_009", "B25007_010", "B25007_011",
    #              "B25007_019", "B25007_020", "B25007_021")
    # ),
    hhrace_bins = list(
      PRACWHT = "B02001_002",
      PRACBLK = "B02001_003",
      PRACNAT = "B02001_004",
      PRACASN = "B02001_005",
      PRACPAC = "B02001_006",
      PRACOTH = "B02001_007",
      PRACMUL = "B02001_008"
    ),
    hhinc_bins = list(
      HHINC1 = c("B19001_002", "B19001_003", "B19001_004"),
      HHINC2 = c("B19001_005", "B19001_006", "B19001_007", "B19001_008", "B19001_009"),
      HHINC3 = c("B19001_010", "B19001_011", "B19001_012"),
      HHINC4 = c("B19001_013", "B19001_014", "B19001_015", "B19001_016", "B19001_017")
    )
  )
  # Bins
  tract_bins = list(
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
  
  
  # Aggregate & cleanup block groups
  bg_agg = rbindlist(lapply(bg_bins, function(b) {
    rbindlist(lapply(names(b), function(x) {
      bg_raw[variable %in% b[[x]], .('value'=sum(estimate), 'label' = x), by = GEOID]
    }))
  }))
  
  bg_data = dcast(bg_agg, 
                  GEOID~label,
                  value.var = 'value'
  )[,c('GEOID', unlist(sapply(bg_bins, names), use.names=F)), with=F]
  
  # bg_data[ , TRACTGEOID := truncate_geoid(GEOID, 'tract')]
  
  
  # Aggregate & cleanup tracts
  tract_agg = rbindlist(lapply(tract_bins, function(b) {
    rbindlist(lapply(names(b), function(x) {
      tract_raw[variable %in% b[[x]], .('value'=sum(estimate), 'label' = x), by = GEOID]
    }))
  }))
  
  tract_data = dcast(tract_agg, 
                     GEOID~label,
                     value.var = 'value'
  )[,c('GEOID', unlist(sapply(tract_bins, names), use.names=F)), with=F]
  
  # Name differentiation
  setnames(tract_data,'GEOID','TRACTGEOID')
  
  return(list('tract' = tract_data, 'bg' = bg_data))
  
}

# Function to fetch and format PUMS data using tidycensus
fetch_pumsdata = function(autocfg) {
  #### PUMS SEED ####
  YEAR = autocfg$ACS_YEAR
  STATE = autocfg$STATE
  
  # Latest pums year
  PUMS_YEAR = pums_variables %>% 
    mutate(year=as.integer(year)) %>%
    filter(year <= YEAR) %>% 
    select(year) %>% max()
  
  # use this to look for the vars we need
  pums_vars = pums_variables %>% 
    filter(year == PUMS_YEAR, survey == "acs5") %>% 
    distinct(var_code, var_label, data_type, level)
  
  # list the vars we need
  pums_vars_vec = c("SERIALNO", "PUMA", "ST", "WGTP", "PWGTP", "SPORDER",
                    "AGEP", "NP", "HINCP", "PINCP", "ADJINC", "TYPE",
                    "ESR", "RAC1P", "BLD") 
  
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
  pums_data[ , hhnum := .GRP, by = SERIALNO]
  
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
bzones_to_census = function(SOURCE_DATA, how = 'centroid') {
  
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
  }
  

  ggplot() + 
    geom_sf(data=census_bzone, aes(fill='GEOID')) +
    geom_sf(data=bzone_hull, alpha=0.5) +
    geom_sf(data=bzone_latlon) +
    theme_bw()
  
  
  return(census_bzone)

}

# Main function to setup population sim
setup_populationsim = function(
    cfg_dir='../runtime/populationsim/popsim_settings.yaml'
    ) {
  
  # Read config yaml
  cfg = read_yaml(cfg_dir)
  
  # Setup python environment
  # initialize conda env if not already done
  if(!('popsimR' %in% conda_list()$name)) {
    conda_create(envname = 'popsimR',
                 packages = 'pytables',
                 python_version = '3.9')
    py_install('populationsim', envname = 'popsimR', pip=TRUE)
  }
  
  # Setup the directory paths
  RUNTIME_DIR = VEModel::getRuntimeDirectory()
  MODEL_DIR = append_root(cfg$MODEL_DIR)
  POPSIM_DIR = file.path(MODEL_DIR, 'populationsim')
  TEMPLATE_DIR = file.path(RUNTIME_DIR, 'populationsim/populationsim_template')
  
  # Check source data validity
  SOURCE_DATA = lapply(names(cfg$AUTO_DATA_PREP$SOURCE_DATA), function(file_name) {
    FP = cfg$AUTO_DATA_PREP$SOURCE_DATA[[file_name]]
    FP = append_root(FP, MODEL_DIR)
    if (!file.exists(FP)) stop(paste("Can't find file for", file_name))
    return(FP)
  })
  names(SOURCE_DATA) = names(cfg$AUTO_DATA_PREP$SOURCE_DATA)
  
  
  # Copy template to model directory
  if (dir.exists(POPSIM_DIR)) unlink(POPSIM_DIR, recursive = TRUE)
  file.copy(from=TEMPLATE_DIR, to=MODEL_DIR, recursive = TRUE)
  file.rename(file.path(MODEL_DIR,'populationsim_template'), POPSIM_DIR)
  
  
  ### Automated data prep
  # Get list of GEOIDs that 
  census_bzone = bzones_to_census(SOURCE_DATA, how='centroid')
  
  # Tract to PUMAS
  puma_xwalk = fread(SOURCE_DATA$PUMA_XWALK, colClasses = 'character')

  # Get basic elements
  geo_xwalk = merge(data.table(census_bzone)[,.(STATEFP,COUNTYFP,TRACTCE,BLKGRPCE,GEOID)],
                    puma_xwalk, on=.(STATEFP, COUNTYFP, TRACTCE))
  geo_xwalk[ , TRACTGEOID := truncate_geoid(GEOID, 'tract')]
  geo_xwalk[ , REGION := 1]
  setnames(geo_xwalk, 'PUMA5CE', "PUMA")
  
  # Fetch PUMS data
  pums_data = fetch_pumsdata(cfg$AUTO_DATA_PREP)
  
  # Fetch ACS data
  acs_data = fetch_acsdata(cfg$AUTO_DATA_PREP, bg_list=unique(geo_xwalk$GEOID))
  bg_data = acs_data[['bg']]
  tract_data = acs_data[['tract']]
  
  #### FINAL PUMS SEED DATA ###
  # HH/PER vars
  base_vars = c('SERIALNO', 'hhnum', 'PUMA', 'REGION')
  hh_vars = c(base_vars, 'NP', 'NW', 'HHINCADJ', 'WGTP', 'HTYPE')
  per_vars = c(base_vars, 'SPORDER', 'PWGTP', 'RAC1P', 'AGEP', 'PINCADJ', 'WORKER')
  
  # Extract & format seed data
  seed_pums_hh = unique(pums_data[,hh_vars, with=F])
  seed_pums_per = pums_data[,per_vars, with=F]
  
  
  #### FINAL CONTROL TOTALS ####
  # BG totals
  control_totals_bg = merge(
    geo_xwalk[,!'BLKGRPCE'], 
    acs_data[['bg']],
    by='GEOID')
  
  # tract totals
  control_totals_tract = merge(
    unique(geo_xwalk[,!c('BLKGRPCE', 'GEOID')]),
    acs_data[['tract']],
    by='TRACTGEOID')
  
  #### SCALED TOTALS ####
  
  # Trust blocks b/c tract might overlap outside of region
  scaled_control_totals_meta = colSums(tract_data[,!c("TRACTGEOID","POPBASE")])
  scaled_control_totals_meta = scaled_control_totals_meta * bg_data[,sum(POPBASE)] / tract_data[,sum(POPBASE)]
  scaled_control_totals_meta = round(scaled_control_totals_meta)
  
  # Add in the block totals
  scaled_control_totals_meta = as.data.table(t(
    c("REGION"=1,
      scaled_control_totals_meta, 
      colSums(bg_data[,!c("GEOID"), with=F])
      )
  ))
  
  
  ### CONFIRM GEOGRAPHY NAMES ####
  # setnames(geo_cross_walk, c('TRACTGEOID', 'GEOID'), c('TRACT', 'BG'))
  # setnames(control_totals_bg, c('TRACTGEOID', 'GEOID'), c('TRACT', 'BG'))
  # setnames(control_totals_tract, 'TRACTGEOID', 'TRACT')
  
  
  #### SAVE OUTPUT ####
  fwrite(geo_xwalk, file.path(POPSIM_DIR, 'data/geo_cross_walk.csv'))
  fwrite(control_totals_bg, file.path(POPSIM_DIR, 'data/control_totals_bg.csv'))
  fwrite(control_totals_tract, file.path(POPSIM_DIR, 'data/control_totals_tract.csv'))
  fwrite(seed_pums_hh, file.path(POPSIM_DIR, 'data/seed_households.csv'))
  fwrite(seed_pums_per, file.path(POPSIM_DIR, 'data/seed_persons.csv'))
  fwrite(scaled_control_totals_meta, file.path(POPSIM_DIR, 'data/scaled_control_totals_meta.csv'))
}


run_populationsim = function(cfg_dir='../runtime/populationsim/popsim_settings.yaml') {
  
  POPSIM_DIR = append_root(file.path(settings$MODEL_DIR, 'populationsim'))
  
  if(!dir.exists(file.path(POPSIM_DIR,'output'))) {
    dir.create(file.path(POPSIM_DIR,'output'))
  }
  
  use_condaenv('popsim', required = TRUE)
  import('activitysim')
  
  command = sprintf('python %s/run_populationsim.py --working_dir %s', POPSIM_DIR, POPSIM_DIR)
  system(command, wait=TRUE, invisible = FALSE)
  
}


