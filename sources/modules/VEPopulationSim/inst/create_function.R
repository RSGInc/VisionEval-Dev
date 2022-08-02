library(data.table)
library(here)

module_dir <- here(here(), "sources", "modules", "VEPopulationSim")
syn_pop_file <- "synthetic_persons.csv"
syn_hh_file <- "synthetic_households.csv"
r_output_script <- "ReadPopulationSimOutput.R"

function_text <- paste0(readLines(here(module_dir,"inst", "ve_read_popsim_output_function.R")),
                        collapse = "\n")


spec_text <- paste0(readLines(here(module_dir,"R", r_output_script)),
                    collapse = "\n")


final_text <- paste0(spec_text, paste0(rep("\n", 3), collapse = ""), function_text)

writeLines(final_text, here(module_dir, "R", r_output_script))