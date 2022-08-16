# VENHTS
NHTS data package

This package processes a NHTS publically available dataset to create a household dataset which is used for model estimations. The NHTS data are augmented with transportation service data. 

The user can define the NHTS year, although this version of the package has been created to work only with the 2001 and 2017 NHTS survey datasets. The ```NHTSYEAR```variable in the ```MakeNHTSDataset.R``` script can be set to either 2001 or 2017 and the package will update to use the selected version of the NHTS when the package is built. 

Users are cautioned to be aware of the version of the NHTS that they are using, variable consistency, naming, and other differences between NHTS versions. 

See [Getting Started](https://github.com/VisionEval/VisionEval/wiki/Getting-Started)
