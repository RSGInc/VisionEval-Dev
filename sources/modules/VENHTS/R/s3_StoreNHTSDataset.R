#=====================
#Make2001NHTSDataset.R
#=====================
#This module creates a data frame of data from the publically available data
#from the 2001 National Household Travel Survey (NHTS) augmented with data on
#metropolitan area freeway supply and transit supply. The package produces a
#data frame of values by household.

if(!dir.exists("data")) dir.create("data")

#==========================
#SAVE THE HOUSEHOLD DATASET
#==========================
#' Household travel from the 2001 National Household Travel Survey
#'
#' A household dataset containing the data used for estimating VisionEval
#' travel models derived from the 2001 National Household Travel Survey, USDOT
#' Highway Statistics reports, and the National Transit Database.
#'
#' @format A data frame with 60521 rows and 86 variables
#' \describe{
#'   \item{Houseid}{Unique household ID}
#'   \item{Census_d}{Household Census division}
#'   \item{Census_r}{Household Census region}
#'   \item{Drvrcnt}{Count of drivers in household}
#'   \item{Expflhhn}{HH Weight-100 percent completed - NATL}
#'   \item{Expfllhh}{HH Weight-100 percent completed}
#'   \item{Flgfincm}{Incomes of all HH members included}
#'   \item{Hbhresdn}{Housing units per sq mile - Block group}
#'   \item{Hbhur}{Urban / Rural indicator - Block group}
#'   \item{Hbppopdn}{Population per sq mile - Block group}
#'   \item{Hhc_msa}{MSA / CMSA code for HH}
#'   \item{Hhfaminc}{Total HH income last 12 months (category)}
#'   \item{Hhincttl}{Total income all HH members (category)}
#'   \item{Hhnumbik}{Number of full size bicycles in HH}
#'   \item{Hhr_age}{Respondent age}
#'   \item{Hhr_drvr}{Driver status of HH respondent}
#'   \item{Hhr_race}{Race of HH respondent}
#'   \item{Hhr_sex}{Gender of HH respondent}
#'   \item{Hhsize}{Count of HH members}
#'   \item{Hhvehcnt}{Count of vehicles in HH}
#'   \item{Hometype}{Type of housing unit}
#'   \item{Hteempdn}{Workers per square mile living in Tract}
#'   \item{Hthresdn}{Housing units per sq mile - Tract level}
#'   \item{Hthur}{Urban / Rural indicator - Tract level}
#'   \item{Htppopdn}{Population per sq mile - Tract level}
#'   \item{Lif_cyc}{HH Life Cycle}
#'   \item{Msapop}{Number of persons residing in the MSA}
#'   \item{Msacat}{MSA category}
#'   \item{Msasize}{MSA size}
#'   \item{Rail}{Rail (subway) category}
#'   \item{Ratio16v}{Ratio - HH members (16+) to vehicles}
#'   \item{Urban}{Household in urbanized area}
#'   \item{Urbrur}{Household in urban/rural area}
#'   \item{Wrkcount}{Count of HH members with jobs}
#'   \item{Cnttdhh}{Sum of all travel period person trips}
#'   \item{Age0to14}{Number of persons age 0 to 14 in household}
#'   \item{Age15to19}{Number of persons age 15 to 19 in household}
#'   \item{Age20to29}{Number of persons age 20 to 29 in household}
#'   \item{Age30to54}{Number of persons age 30 to 54 in household}
#'   \item{Age55to64}{Number of persons age 55 to 64 in household}
#'   \item{Age65Plus}{Number of persons age 65 or older in household}
#'   \item{Drv15to19}{Number of drivers 15 to 19 in household}
#'   \item{Drv20to29}{Number of drivers 20 to 29 in household}
#'   \item{Drv30to54}{Number of drivers 30 to 54 in household}
#'   \item{Drv55to64}{Number of drivers 55 to 64 in household}
#'   \item{Drv65Plus}{Number of drivers 65 or older in household}
#'   \item{Wkr15to19}{Number of workers 15 to 19 in household}
#'   \item{Wkr20to29}{Number of workers 20 to 29 in household}
#'   \item{Wkr30to54}{Number of workers 30 to 54 in household}
#'   \item{Wkr55to64}{Number of workers 55 to 64 in household}
#'   \item{Wkr65Plus}{Number of workers 65 or older in household}
#'   \item{Income}{Household income}
#'   \item{IncGrp}{Household income group}
#'   \item{UrbanDev}{Flag identifying whether household lived in an 'Urban' area}
#'   \item{TownDev}{Flag identifying whether household lived in a 'Town' area}
#'   \item{SuburbanDev}{Flag identifying whether household lived in a 'Suburban' area}
#'   \item{RuralDev}{Flag identifying whether household lived in a 'Rural' area}
#'   \item{SecondCityDev}{Flag identifying whether household lived in a 'Second City' area}
#'   \item{NumAuto}{Number of automobiles owned}
#'   \item{NumLightTruck}{Number of light trucks owned}
#'   \item{NumVeh}{Number of vehicles (autos and light trucks) owned}
#'   \item{VehPerDrvAgePop}{Ratio of household vehicles and driving-age persons}
#'   \item{Totmiles}{Total annual household miles calculated from best estimate of annual vehicle miles 'BESTMILE'}
#'   \item{AveMpg}{Average MPG of household vehicles}
#'   \item{Gscost}{Average cost of gasoline per gallon}
#'   \item{Gscostmile}{Average cost of gasoline per mile of household vehicle travel}
#'   \item{Gscostmile2}{Average cost of gasoline per mile using EIA derived miles per equivalent-gallon}
#'   \item{PvtVehDvmt}{Household vehicle miles of travel on survey day using household (i.e. private) vehicles}
#'   \item{PvtVehTrips}{Household vehicle trips on survey day using household (i.e. private) vehicles}
#'   \item{ShrVehDvmt}{Household vehicle miles of travel on survey day using non-household (i.e. shared) vehicles}
#'   \item{ShrVehTrips}{Household vehicle trips on survey day using non-household (i.e. shared) vehicles}
#'   \item{WalkDpmt}{Household person miles of walking on survey day}
#'   \item{BikeDpmt}{Household person miles of bicycling on survey day}
#'   \item{TransitDpmt}{Household person miles of public transit travel on survey day}
#'   \item{TransitTrips}{Household transit trips on survey day}
#'   \item{ZeroDvmt}{Flag identifying whether household had no DVMT on survey day}
#'   \item{Numcommdrvr}{Number of commercial drivers in household}
#'   \item{Nbiketrp}{Number of bike trips in past week}
#'   \item{Nwalktrp}{Number of walk trips in past week}
#'   \item{Usepubtr}{Whether any household members used public transportation on travel survey day}
#'   \item{Numwrkdrvr}{Number of persons whose work requires driving a vehicle}
#'   \item{RoadMiPC}{Ratio of urbanized area road miles to thousands of persons}
#'   \item{FwyLnMiPC}{Ratio of urbanized area freeway lane miles to thousands of persons}
#'   \item{MsaPopDen}{Urbanized area population density in persons per square mile}
#'   \item{BusEqRevMiPC}{Annual bus equivalent transit revenue miles per capita}
#'   \item{LargeHh}{Flag identifying whether household size is large}
#' }
#' @source 2001 National Household Travel Survey, Highway Statistics (2001),
#' National Transit Database (2002), and Make2001NHTSDataset.R script.
"Hh_df"
if ( exists("Hh_df") ) visioneval::savePackageDataset(Hh_df, overwrite = TRUE)


#========================
#SAVE THE VEHICLE DATASET
#========================
#' Vehicle dataset from the 2001 National Household Travel Survey
#'
#' A vehicle dataset containing the data used for estimating VisionEval
#' vehicle models derived from the 2001 National Household Travel Survey.
#'
#' @format A data frame with 112697 rows and 10 variables
#' \describe{
#'   \item{Houseid}{Unique household ID}
#'   \item{Vehid}{Unique ID for vehicle in household}
#'   \item{Bestmile}{Best estimate of annual miles}
#'   \item{Eiadmpg}{EIA derived miles per equivalent-gallon}
#'   \item{Gscost}{Estimated Fuel cost (cents per gallon)}
#'   \item{Vehtype}{Type of vehicle}
#'   \item{Vehyear}{Vehicle year - derived}
#'   \item{Vehmiles}{Miles vehicle driven last 12 months}
#'   \item{Type}{Auto or light truck}
#'   \item{Gscostmile2}{Estimated gas cost per mile of travel}
#' }
#' @source 2001 National Household Travel Survey and Make2001NHTSDataset.R script.
"Veh_df"
if ( exists("Veh_df") ) visioneval::savePackageDataset(Veh_df, overwrite = TRUE)


#=====================
#SAVE THE TOUR DATASET
#=====================
#' Household tour dataset from the 2001 National Household Travel Survey
#'
#' A dataset of household tours (shared person tours) derived from the 2001
#' National Household Travel Survey and used in the estimation of several
#' VisionEval models.
#'
#'  @format A data frame with 154270 rows and 16 columns.
#'  \describe{
#'    \item{Houseid}{Unique household ID}
#'    \item{Distance}{Total distance in miles of the tour}
#'    \item{TravelTime}{Total time in minutes spent traveling on the tour}
#'    \item{DwellTime}{Total time in minutes spent at activities on the tour}
#'    \item{StartHome}{Logical identifying if the tour started at home}
#'    \item{EndHome}{Logical identifying if the tour ended at home}
#'    \item{Trips}{Number of trips in the tour}
#'    \item{Persons}{Number of persons on the tour}
#'    \item{Vehid}{Unique ID for vehicle in household}
#'    \item{Trptrans}{Mode of transportation (see 2001 NHTS codebook for TRPTRANS)}
#'    \item{Vehtype}{Type of vehicle used (see 2001 NHTS codebook for VEHTYPE)}
#'    \item{HhVehUsed}{Whether household vehicle used (1=yes, 2=no)}
#'    \item{Whyto}{String contenating successive activity codes at trip end (see 2001 NHTS codebook for WHYTO)}
#'    \item{Disttowk}{Distance from home to work for the person on the tour who works farthest from home}
#'    \item{Mode}{Simplified travel mode category (see script for definitions)}
#'    \item{IncludesWork}{Logical identifying whether tour includes a work activity (codes 10, 11, 12, 13, 14)}
#'  }
#'  @source 2001 National Household Travel Survey and Make2001NHTSDataset.R script.
"HhTours_df"
if ( exists("HhTours_df") ) visioneval::savePackageDataset(HhTours_df, overwrite = TRUE)


#=======================
#SAVE THE PERSON DATASET
#=======================
#' Person dataset from the 2001 National Household Travel Survey
#'
#' A dataset of person characteristics derived from the 2001 National Household
#' Travel Survey and used in the estimation of several VisionEval models.
#'
#'  @format A data frame with 144884 rows and 14 columns.
#'  \describe{
#'    \item{Houseid}{Unique household ID}
#'    \item{Personid}{Unique ID of person in household}
#'    \item{Commdrvr}{Person is a commercial driver}
#'    \item{Nbiketrp}{Number of bike trips in past week}
#'    \item{Nwalktrp}{Number of walk trips in past week}
#'    \item{Usepubtr}{Used public transit on travel day}
#'    \item{Wrkdrive}{Job requires driving a motor vehicle}
#'    \item{Wrktrans}{Transportation mode to work last week}
#'    \item{Worker}{Person has job (1=yes, 0=no)}
#'    \item{Dtgas}{Price of gasoline}
#'    \item{Disttowk}{Distance to work in miles}
#'    \item{Driver}{Driver status (1=driver, 0=non-driver)}
#'    \item{R_age}{Age}
#'    \item{R_sex}{Sex}
#'    \item{AgeGroup}{AgeGroup: Age0to14, Age15to19, Age20to29, Age30to54, Age55to64, Age65Plus}
#'  }
#'  @source 2001 National Household Travel Survey and Make2001NHTSDataset.R script.
"Per_df"
if ( exists( "Per_df" ) ) visioneval::savePackageDataset(Per_df, overwrite = TRUE)

rm(list=ls())
