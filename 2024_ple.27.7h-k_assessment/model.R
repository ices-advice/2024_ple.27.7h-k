### ------------------------------------------------------------------------ ###
### Apply rfb rule ####
### ------------------------------------------------------------------------ ###

## Before: data/idx.csv
##         data/advice_history.csv
##         data/length_data.rds
## After:  model/advice.rds

# R version 4.4.0

library(icesTAF)
taf.libPaths()
library(cat3advice)
library(dplyr)

mkdir("model")

### ------------------------------------------------------------------------ ###
### load data ####
### ------------------------------------------------------------------------ ###

### history of catch and advice
catch <- read.taf("data/advice_history.csv")
catch_A <- catch %>%
  select(year, advice = ICES_advice, discards = ICES_discards,
         landings = ICES_landings , catch = ICES_catch)

### biomass index
idxB <- read.taf("data/idx.csv")

### catch length data
lngth <- read.taf("data/length_data.csv")

### ------------------------------------------------------------------------ ###
### reference catch ####
### ------------------------------------------------------------------------ ###
### use last catch advice (advice given in 2022 for 2023 and 2024)
A <- A(catch_A[catch_A$year <= 2024, ], units = "tonnes", 
       basis = "advice", advice_metric = "catch")

### ------------------------------------------------------------------------ ###
### r - biomass index trend/ratio ####
### ------------------------------------------------------------------------ ###
### 2 over 3 ratio
r <- rfb_r(idxB, units = "Estimate_metric_tons")

### ------------------------------------------------------------------------ ###
### b - biomass safeguard ####
### ------------------------------------------------------------------------ ###
### do not redefine biomass trigger Itrigger and keep value defined in 2024
### Itrigger based on Iloss (2007)
b <- rfb_b(idxB, units = "Estimate_metric_tons", yr_ref = 2005)

### ------------------------------------------------------------------------ ###
### f - length-based indicator/fishing pressure proxy ####
### ------------------------------------------------------------------------ ###

### calculate annual length at first capture - for information only
lc_annual <- Lc(lngth, units = "mm")

### Lc was defined at WGCSE 2024 by using data from 2017:2021
### keep this definition (do not update Lc)
lc <- Lc(lngth, average = 2017:2021, units = "mm") #same as benchmark, pool to average cause variability in sample size #dont trust labels 
#lc <- Lc(228, units = "mm")

### mean annual catch length above Lc
lmean <- Lmean(lngth, Lc = lc, units = "mm")
#high variability in time series so we use the mean of time series 
#lmean <- mean(lmean@summary$Lmean)

### reference length LF=M - keep value calculated at WGCSE 2022
### Linf calculated by fitting von Bertalanffy model to age-length data

lref <- Lref(basis = "LF=M", Lc = lc, Linf = 467, units = "mm")

### length indicator
f <- rfb_f(Lmean = lmean, Lref = lref, units = "mm")

### ------------------------------------------------------------------------ ###
### multiplier ####
### ------------------------------------------------------------------------ ###
### generic multiplier based on life history (von Bertalanffy k)
### k value from fitting von Bertalanffy model to survey age-length data

m <- rfb_m(k = 0.18)

### ------------------------------------------------------------------------ ###
### discard rate ####
### ------------------------------------------------------------------------ ###
discard_rate <- 35


### ------------------------------------------------------------------------ ###
### apply rfb rule - combine elements ####
### ------------------------------------------------------------------------ ###
### includes consideration of stability clause

advice <- rfb(A = A, r = r, f = f, b = b, m = m,
              cap = "conditional", cap_upper = 20, cap_lower = -30,
              frequency = "biennial", 
              discard_rate = 35)

### ------------------------------------------------------------------------ ###
### save output ####
### ------------------------------------------------------------------------ ###
saveRDS(advice, file = "model/advice.rds")
saveRDS(lc_annual, file = "model/lc_annual.rds")


