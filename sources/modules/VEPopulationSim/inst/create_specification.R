library(data.table)
library(here)

inp_dictionary_file <- here(module_dir, "inst", "PopulationSim_DataDictionary.csv")
set_dictionary_file <- here(module_dir, "inst", "VESimHousehold_DataDictionary.csv")

inp_dict_dt <- fread(inp_dictionary_file)
inp_dict_dt[,NAME:=paste0("\"", NAME,"\"")]
inp_dict_dt[,FILE:=paste0("\"", FILE,"\"")]
inp_dict_dt[,TABLE:=paste0("\"", TABLE,"\"")]
inp_dict_dt[,TYPE:=paste0("\"", TYPE,"\"")]
inp_dict_dt[,GROUP:=paste0("\"", GROUP,"\"")]
inp_dict_dt[,UNITS:=paste0("\"", UNITS,"\"")]
inp_dict_dt[,DESCRIPTION:=paste0("\"", DESCRIPTION,"\"")]
inp_dict_dt[ISELEMENTOF=="",ISELEMENTOF:='"""']


get_dict_dt <- copy(inp_dict_dt)
get_dict_dt[TYPE=="\"currency\"", UNITS:=paste0(strtrim(UNITS,nchar(UNITS)-1),".", Year,"\"")]

set_dict_dt <- fread(set_dictionary_file)
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




specification_text <- paste0(specification_text,paste0(rep("\n",2), collapse = ""),
                             '#Save the data specifications list\n#---------------------------------
\n#\' Specifications list for ReadPopulationSimOutput module
#\'
#\' A list containing specifications for the ReadPopulationSimOutput module.
#\'
#\' @format A list containing 5 components:
#\' \\describe{
#\'  \\item{RunBy}{the level of geography that the module is run at}
#\'  \\item{NewSetTable}{new table to be created for datasets specified in the
#\'  \'Set\' specifications}
#\'  \\item{Inp}{scenario input data to be loaded into the datastore for this
#\'  module}
#\'  \\item{Get}{module inputs to be read from the datastore}
#\'  \\item{Set}{module outputs to be written to the datastore}
#\' }
#\' @source ReadPopulationSimOutput.R script.
"ReadPopulationSimOutputSpecifications"
visioneval::savePackageDataset(ReadPopulationSimOutputSpecifications, overwrite = TRUE)')

writeLines(specification_text, here(module_dir, "R", "ReadPopulationSimOutput.R"))

# cat(paste0(apply(inp_dict_dt,1,create_items), collapse = ",\n"))