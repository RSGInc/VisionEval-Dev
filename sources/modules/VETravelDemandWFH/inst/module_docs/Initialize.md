# Initialize Module
### February 27, 2023

Modules in the VETravelDemandWFH package includes modules that predicts the amount of time each worker in a houshold works from home and the resulting change in their commute distance

It also includes modules that calculate household DVMT and alternate mode trips while accounting for teleworking behavior.

The teleworking module uses a user input file 'azone_wkr_loc_type_occupation_prop.csv' to predict teleworking behavior.

It is incumbent on the model user to identify if this file is consistent with 'azone_hh_loc_type_prop.csv'.

This module includes a number of input checks to avoid data inconsistencies that could cause the model run to fail. Errors and warnings are produced to identify these errors and warnings:

* The proportions of workers by location type for each Azone ('PropRuralOnSite', 'PropRuralMixed', 'PropRuralRemote' for Rural, 'PropTownOnSite', 'PropTownMixed', 'PropTownRemote' for Town, and 'PropMetroOnSite', 'PropMetroMixed', 'PropMetroRemote' for Metro in the 'azone_wkr_loc_type_occupation_prop.csv' file) are checked to confirm that they add up to 1 by location type. If the sum is off by more than 1%, then an error is identified. The error message identifies the Azones and Years that the data is incorrect. If the sum is off by less than 1% the proportions are rescaled to sum to 1 and a warning is identified. The warning message identifies the Azones and Years that the data doesn't sum to 1.
* The proportions of workers by location type for each Azone ('PropRuralOnSite', 'PropRuralMixed', 'PropRuralRemote' for Rural, 'PropTownOnSite', 'PropTownMixed', 'PropTownRemote' for Town, and 'PropMetroOnSite', 'PropMetroMixed', 'PropMetroRemote' for Metro in the 'azone_wkr_loc_type_occupation_prop.csv' file) are checked to confirm that they are consisten with the existence of households in the location type by azone as proposed in the file 'azone_hh_loc_type_prop.csv'.

## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### azone_hh_loc_type_prop.csv
|   |NAME        |TYPE   |UNITS      |PROHIBIT     |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                 |
|:--|:-----------|:------|:----------|:------------|:-----------|:--------|:-------------------------------------------------------------------------------------------|
|1  |Geo         |       |           |             |Azones      |         |Must contain a record for each Azone and model run year.                                    |
|13 |Year        |       |           |             |            |         |Must contain a record for each Azone and model run year.                                    |
|10 |PropMetroHh |double |proportion |NA, < 0, > 1 |            |         |Proportion of households residing in the metropolitan (i.e. urbanized) part of the Azone    |
|11 |PropTownHh  |double |proportion |NA, < 0, > 1 |            |         |Proportion of households residing in towns (i.e. urban-like but not urbanized) in the Azone |
|12 |PropRuralHh |double |proportion |NA, < 0, > 1 |            |         |Proportion of households residing in rural (i.e. not urbanized or town) parts of the Azone  |
### azone_wkr_loc_type_occupation_prop.csv
|NAME            |TYPE   |UNITS      |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                              |
|:---------------|:------|:----------|:--------|:-----------|:--------|:--------------------------------------------------------|
|Geo             |       |           |         |Azones      |         |Must contain a record for each Azone and model run year. |
|Year            |       |           |         |            |         |Must contain a record for each Azone and model run year. |
|PropRuralOnSite |double |proportion |NA       |            |         |PropRuralOnSite                                          |
|PropRuralMixed  |double |proportion |NA       |            |         |PropRuralMixed                                           |
|PropRuralRemote |double |proportion |NA       |            |         |PropRuralRemote                                          |
|PropTownOnSite  |double |proportion |NA       |            |         |PropTownOnSite                                           |
|PropTownMixed   |double |proportion |NA       |            |         |PropTownMixed                                            |
|PropTownRemote  |double |proportion |NA       |            |         |PropTownRemote                                           |
|PropMetroOnSite |double |proportion |NA       |            |         |PropMetroOnSite                                          |
|PropMetroMixed  |double |proportion |NA       |            |         |PropMetroMixed                                           |
|PropMetroRemote |double |proportion |NA       |            |         |PropMetroRemote                                          |

## Datasets Used by the Module
This module uses no datasets that are in the datastore.

## Datasets Produced by the Module
This module produces no datasets to store in the datastore.
