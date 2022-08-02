library(here)
# List all the paths for writing the R Scripts
module_dir <- here(here(), "sources", "modules", "VEPopulationSim")
create_spec_file <- "create_specification.R"
create_func_file <- "create_function.R"

# Write the R script
source(here(module_dir, "inst", create_spec_file), echo = TRUE)
source(here(module_dir, "inst", create_func_file), echo = TRUE)

# List all the paths to update the synthetic population files
syn_pop_file <- "synthetic_persons.csv"
syn_hh_file <- "synthetic_households.csv"
Year <- "2020"
popsim_example_dir <- here(module_dir, "populationsim_example")
popsim_output_dir <- here(popsim_example_dir, "output")

# Update the synthetic population that can be used by the 
# VEPopulationSim package
syn_pop_dt <- fread(here(popsim_output_dir, syn_pop_file))
syn_hh_dt <- fread(here(popsim_output_dir, syn_hh_file))

setnames(syn_hh_dt, "HHINCADJ", "HHINCADJ.2020")
setnames(syn_pop_dt, "PINCADJ", "PINCADJ.2020")

fwrite(syn_hh_dt, here(module_dir, "inst", "models", "inputs", syn_hh_file))
fwrite(syn_pop_dt, here(module_dir, "inst", "models", "inputs", syn_pop_file))
