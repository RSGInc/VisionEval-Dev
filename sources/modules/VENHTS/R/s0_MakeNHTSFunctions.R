#Define functions
#----------------

#Define function to retrieve NHTS dataset from repository, unzip, and read as
#data frame
#----------------------------------------------------------------------------
#' Retrieve data in zip archive from repository
#'
#' \code{getZipDatasetFromRepo} retrieve a zip archive containing a csv file
#' from a repository, unzip, and read as data frame
#'
#' This function retrieves a zip archive containing a csv file from a
#' repository, unzips it, and reads it in as data frame which it returns.
#'
#' @param Repo A string that is the url where the zip archive is located.
#' @param DatasetName The name of the dataset.
#' @return A data frame containing the data in the zip archive.
#' @import utils
# getZipDatasetFromRepo <- function(Repo, DatasetName) {
#   ZipArchiveFileName <- paste0(DatasetName, ".zip")
#   CsvFileName <- paste0(DatasetName, ".csv")
#   download.file(file.path(Repo, ZipArchiveFileName), ZipArchiveFileName)
#   Data_df <- read.csv(unzip(ZipArchiveFileName), as.is = TRUE)
#   file.remove(ZipArchiveFileName, CsvFileName)
#   Data_df
# }
# Updated to get from source
getZipDatasetFromRepo <- function(Repo, DatasetName) {
  temp <- tempfile()
  download.file(Repo, temp)
  con <- unz(temp, paste0(DatasetName, ".csv"))
  Data_df <- read.csv(con)
  unlink(temp)
  Data_df
}


#Define function to convert name to proper name (only first letter capitalized)
toProperName <- function(X){
  EndX <- nchar(X)
  paste(toupper(substring(X, 1, 1)), tolower(substring(X, 2, EndX)), sep="")
}

#Define function to convert 1-dimensional array into a named vector
toVecFrom1DAry <- function(X_ar){
  X_ <- as.vector(X_ar)
  names(X_) <- names(X_ar)
  X_
}

#Define function to convert numbers to strings and add leading zeros if
#necessary so that every one has 2 characters (e.g. '1' becomes 01)
doPadNum <- function(Num_) {
  Num_ <- as.character(Num_)
  Num_[nchar(Num_) < 2] <- paste0(0, Num_[nchar(Num_) < 2])
  Num_
}


#Define function to process person tours
getPersonTours <- function(PTrp_df, replaceNA = FALSE) {
  if (replaceNA) {
    WhyFrom_ <- PTrp_df$Whyfrom
    WhyTo_ <- PTrp_df$Whyto
    NaIdx_ <- which(is.na(WhyFrom_))
    for (i in NaIdx_) {
      if (i == 1) {
        WhyFrom_[i] <- 1
      } else {
        WhyToLag <- WhyTo_[i - 1]
        if (!is.na(WhyToLag) & WhyToLag == 1) {
          WhyFrom_[i] <- 1
        } else {
          WhyFrom_[i] <- 0
        }
      }
    }
    PTrp_df$Whyfrom <- WhyFrom_
  }
  Tours_ls <- split(PTrp_df, cumsum(PTrp_df$Whyfrom == 1))
  do.call(rbind, lapply(Tours_ls, function(x) {
    data.frame(
      Houseid = x$Houseid[1],
      Distance = sum(x$Trpmiles, na.rm = TRUE),
      TravelTime = sum(x$Trvl_min, na.rm = TRUE),
      DwellTime = sum(x$Dweltime, na.rm = TRUE),
      StartHome = x$Whyfrom[1] == 1,
      EndHome = tail(x$Whyto,1) == 1,
      Trips = nrow(x),
      Persons = max(x$Numontrp),
      Vehid = x$Vehused[1],
      Trptrans = x$Trptrans[1],
      Vehtype = x$Vehtype[1],
      HhVehUsed = x$Trphhveh[1],
      Whyto = paste(x$Whyto, collapse = "-"),
      Disttowk = Per_df$Disttowk[Per_df$Personid == x$Personid[1]],
      Signature =
        paste(paste(c(rbind(x$Whyfrom, x$Whyto)), collapse = ""), x$Vehid[1], sep = "-")
    )
  }))
}
#Define function to process household tours, removing duplicated person tour info
getHouseholdTours <- function(HTrp_df) {
  PTrp_ls <- split(HTrp_df, HTrp_df$Personid)
  PTours_df <- do.call(rbind, lapply(PTrp_ls, function(x) {
    if (any(is.na(x$Whyfrom))) {
      getPersonTours(x, TRUE)
    } else {
      getPersonTours(x)
    }
  } ))
  HTours_ls <- split(PTours_df, PTours_df$Signature)
  HTours_df <- do.call(rbind, lapply(HTours_ls, function(x) {
    y <- x[1,]
    if (any(!is.na(x$Disttowk))) {
      y$Disttowk <- max(x$Disttowk, na.rm = TRUE)
    } else {
      y$Disttowk <- NA
    }
    y
  }))
  HTours_df[, -which(names(HTours_df) == "Signature")]
}
