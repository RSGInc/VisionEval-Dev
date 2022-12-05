# PredictIncome Module
### September 6, 2018

This module predicts the income for each simulated household given the number of workers in each age group and the average per capita income for the Azone where the household resides.

## Model Parameter Estimation
Household income models are estimated for *regular* households and for *group quarters* households.

The household income models are estimated using Census public use microsample (PUMS) data that are compiled into a R dataset (HhData_df) by the 'CreateEstimationDatasets.R' script when the VESimHouseholdsCCRPC package is built. The data that are supplied with the VESimHouseholdsCCRPC package downloaded from the VisionEval repository may be used, but it is preferrable to use data for the region being modeled. How this is done is explained in the documentation for the *CreateEstimationDatasets.R* script.

The household income models are linear regression models in which the dependent variable is a power transformation of income. Power transformation is needed in order to normalize the income data distribution which has a long right-hand tail. The power transform is found which minimizes the skewness of the income distribution. The power transform for *regular* households is:

```
0.284
```

The power transform for *group quarters* households is:

```
0.317
```

The independent variables for the linear models are power transformed per capita income for the area, the number of workers in each of 4 worker age groups (15-19, 20-29, 30-54, 55-64), and the number of persons in the 65+ age group. In addition, power-transformed per capita income is interacted with each of the 4 worker groups and 65+ age group variable. The summary statistics for the *regular* household model are as follows:

```

Call:
lm(formula = makeFormula(EndTerms_), data = EstData_df)

Residuals:
     Min       1Q   Median       3Q      Max 
-21.6747  -2.3434  -0.2575   1.9224  27.0387 

Coefficients:
            Estimate Std. Error t value Pr(>|t|)    
(Intercept) 14.65552    0.09582 152.946  < 2e-16 ***
Wkr15to19    0.63696    0.11966   5.323 1.04e-07 ***
Wkr20to29    2.07375    0.07486  27.701  < 2e-16 ***
Wkr30to54    4.00957    0.05980  67.050  < 2e-16 ***
Wkr55to64    4.31851    0.09240  46.738  < 2e-16 ***
Age65Plus    2.11153    0.07884  26.783  < 2e-16 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Residual standard error: 4.155 on 12026 degrees of freedom
Multiple R-squared:  0.3086,	Adjusted R-squared:  0.3083 
F-statistic:  1073 on 5 and 12026 DF,  p-value: < 2.2e-16

```

The summary statistics for the *group quarters* household model are as follows:

```

Call:
lm(formula = makeFormula(EndTerms_), data = EstData_df)

Residuals:
     Min       1Q   Median       3Q      Max 
-15.4352  -3.1329  -0.2037   2.3157  24.9921 

Coefficients:
            Estimate Std. Error t value Pr(>|t|)    
(Intercept)   5.4903     0.5278  10.402  < 2e-16 ***
Wkr15to19     7.3504     0.6011  12.229  < 2e-16 ***
Wkr20to29     8.5762     0.6083  14.099  < 2e-16 ***
Wkr30to54    14.2135     1.2467  11.401  < 2e-16 ***
Wkr55to64    19.3009     3.5209   5.482 5.84e-08 ***
Age65Plus    10.9449     0.8481  12.906  < 2e-16 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Residual standard error: 4.923 on 715 degrees of freedom
Multiple R-squared:  0.2874,	Adjusted R-squared:  0.2824 
F-statistic: 57.67 on 5 and 715 DF,  p-value: < 2.2e-16

```

An additional step must be carried out in order to predict household income. Because the linear model does not account for all of the observed variance, and because income is power distribution, the average of the predicted per capita income is less than the average per capita income of the population. To compensate, random variation needs to be added to each household prediction of power-transformed income by randomly selecting from a normal distribution that is centered on the value predicted by the linear model and has a standard deviation that is calculated so as the resulting average per capita income of households match the input value. A binary search process is used to find the suitable standard deviation. Following is the comparison of mean values for the observed *regular* household income for the estimation dataset and the corresponding predicted values for the estimation dataset.


|          | Dollars|
|:---------|-------:|
|Observed  |   50355|
|Estimated |   50508|

The following figure compares the distributions of the observed and predicted incomes of *regular* households.

![reg-hh-inc_obs-vs-est_distributions.png](reg-hh-inc_obs-vs-est_distributions.png)

Following is the comparison of mean values for the observed *group quarters* household income for the estimation dataset and the corresponding predicted values for the estimation dataset.


|          | Dollars|
|:---------|-------:|
|Observed  |    5404|
|Estimated |    5323|

The following figure compares the distributions of the observed and predicted incomes of *groups quarters* households.

![gq-hh-inc_obs-vs-est_distributions.png](gq-hh-inc_obs-vs-est_distributions.png)

## How the Module Works
This module runs at the Azone level. Azone household average per capita income and group quarters average per capita income are user inputs to the model. The other model inputs are in the datastore, having been created by the CreateHouseholds and PredictWorkers modules. Household income is predicted separately for *regular* and *group quarters* households. Per capita income is transformed using the estimated power transform, the model dependent variables are calculated, and the linear model is applied. Random variation is applied so that the per capita mean income for the predicted household income matches the input value.



## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### azone_per_cap_inc.csv
|NAME       |TYPE     |UNITS |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                         |
|:----------|:--------|:-----|:--------|:-----------|:--------|:-------------------------------------------------------------------|
|Geo        |         |      |         |Azones      |         |Must contain a record for each Azone and model run year.            |
|Year       |         |      |         |            |         |Must contain a record for each Azone and model run year.            |
|HHIncomePC |currency |USD   |NA, < 0  |            |         |Average annual per capita income of households (non-group quarters) |
|GQIncomePC |currency |USD   |NA, < 0  |            |         |Average annual per capita income of group quarters population       |

## Datasets Used by the Module
The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is retrieved from.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year group. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

|NAME       |TABLE     |GROUP |TYPE      |UNITS    |PROHIBIT |ISELEMENTOF |
|:----------|:---------|:-----|:---------|:--------|:--------|:-----------|
|Azone      |Azone     |Year  |character |ID       |         |            |
|HHIncomePC |Azone     |Year  |currency  |USD.1999 |NA, < 0  |            |
|GQIncomePC |Azone     |Year  |currency  |USD.1999 |NA, < 0  |            |
|Azone      |Household |Year  |character |ID       |         |            |
|HhSize     |Household |Year  |people    |PRSN     |NA, <= 0 |            |
|HhType     |Household |Year  |character |category |         |            |
|Wkr15to19  |Household |Year  |people    |PRSN     |NA, < 0  |            |
|Wkr20to29  |Household |Year  |people    |PRSN     |NA, < 0  |            |
|Wkr30to54  |Household |Year  |people    |PRSN     |NA, < 0  |            |
|Wkr55to64  |Household |Year  |people    |PRSN     |NA, < 0  |            |
|Age65Plus  |Household |Year  |people    |PRSN     |NA, < 0  |            |

## Datasets Produced by the Module
The following table documents each dataset that is placed in the datastore by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is placed in.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The native units that are created in the datastore. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

DESCRIPTION - A description of the data.

|NAME   |TABLE     |GROUP |TYPE     |UNITS    |PROHIBIT |ISELEMENTOF |DESCRIPTION                                                |
|:------|:---------|:-----|:--------|:--------|:--------|:-----------|:----------------------------------------------------------|
|Income |Household |Year  |currency |USD.1999 |NA, < 0  |            |Total annual household (non-qroup & group quarters) income |
