library(reticulate)
library(yaml)
library(xfun)

# settings = yaml::read_yaml('../runtime/populationsim/popsim_settings.yaml')
append_root = function(path, root=VEModel::getRuntimeDirectory()) {
  if (!is_abs_path(path)) {
    file.path(root, path)
  } else {
    path
  } 
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
