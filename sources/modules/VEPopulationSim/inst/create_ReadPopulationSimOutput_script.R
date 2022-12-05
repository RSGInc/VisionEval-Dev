library(here)
library(data.table)

# List all the paths for writing the R Scripts
module_dir <- here(here(), "sources", "modules", "VEPopulationSim")
create_spec_file <- "create_specification.R"
create_func_file <- "create_function.R"

# PopulationSim Paths and Constants
popsim_example_dir <- here(module_dir, "populationsim_example") # This should point to PopulationSim working directory
output_dir <- "output"                                          # This should point to the output folder in the PopulationSim working directory.
popsim_output_dir <- here(popsim_example_dir, output_dir)
syn_pop_file <- "synthetic_persons.csv"                         # Name of the synthetic person file
syn_hh_file <- "synthetic_households.csv"                       # Name of the syntthetic household file
Year <- "2017"                                                  # Year for which the PopulationSim synthesizer is run

# Write the R script
source(here(module_dir, "inst", create_spec_file), echo = TRUE)
source(here(module_dir, "inst", create_func_file), echo = TRUE)

# List all the paths to update the synthetic population files
syn_pop_file <- "synthetic_persons.csv"
syn_hh_file <- "synthetic_households.csv"
popsim_example_dir <- here(module_dir, "populationsim_example")
popsim_output_dir <- here(popsim_example_dir, "output")

# Update the synthetic population that can be used by the 
# VEPopulationSim package
syn_pop_dt <- fread(here(popsim_output_dir, syn_pop_file))
syn_hh_dt <- fread(here(popsim_output_dir, syn_hh_file))

setnames(syn_hh_dt, "HHINCADJ", paste0("HHINCADJ.", Year))      # Update the label of the fields that hold currency data
setnames(syn_pop_dt, "PINCADJ", paste0("PINCADJ.", Year))       # Update the label of the fields that hold currency data

fwrite(syn_hh_dt, here(module_dir, "inst", "models", "inputs", syn_hh_file))
fwrite(syn_pop_dt, here(module_dir, "inst", "models", "inputs", syn_pop_file))
