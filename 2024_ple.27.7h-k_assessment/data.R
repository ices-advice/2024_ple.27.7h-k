### ------------------------------------------------------------------------ ###
### Preprocess data, write TAF data tables ####
### ------------------------------------------------------------------------ ###

## Before: boot/data/FSP7e.csv
##         boot/data/advice/advice_history.csv
##         boot/data/InterCatch_length.csv
## After:  data/idx.csv
##         data/advice_history.csv
##         data/length_data.rds
# R version 4.4.0

library(icesTAF)
taf.libPaths()
library(tidyr)
library(dplyr)

taf.bootstrap() #run to create copy of inital folder into data folder

### create folder to store data
mkdir("data")

### ------------------------------------------------------------------------ ###
### Biomass index data ####
### ------------------------------------------------------------------------ ###
### 1 biomass index: VAST index - 5 suveys combined 
### - biomass in estimated metric tonnes

### load data from csv
idxB <- read.csv("boot/data/VAST_biomass.csv")

#Add in confidence intervals (2*SD)
#idxB$confid_inter <- 2*sd(idxB$index)

#Add in confidence intervals (95%)
#To calculate a confidence intervals the following formulas were used.
# Lower bound exp( logn(estimate) – 1.96*logn(SD) )
# Upper bound exp( logn(estimate) + 1.96*logn(SD) )

idxB$Estimate_metric_tons_log <- log(idxB$Estimate_metric_tons)
idxB$Low_StockSize <- exp(idxB$Estimate_metric_tons_log - 1.96*idxB$SD_log)
idxB$High_StockSize  <-exp(idxB$Estimate_metric_tons_log + 1.96*idxB$SD_log)


## Format for cat3advice functions
idxB <- idxB %>% select(Year, index= Estimate_metric_tons, Low_StockSize, High_StockSize )

### save in data directory
write.taf(idxB, file = "data/idx.csv")
saveRDS(idxB, file = "data/idx.rds")


### ------------------------------------------------------------------------ ###
### catch and advice data ####
### ------------------------------------------------------------------------ ###

catch <- read.csv("boot/data/advice_history.csv")
names(catch)[1] <- "year"
write.taf(catch, file = "data/advice_history.csv")
saveRDS(catch, file = "data/advice_history.rds")

### ------------------------------------------------------------------------ ###
### length data ####
### ------------------------------------------------------------------------ ###
### raised data from InterCatch

### load data
lngth_full <- read.csv("boot/data/Canum_Reviewied_Years_SOP_2004-2023.csv")

### summarise data
lngth <- lngth_full %>% 
  ### treat "BMS landing"/"Logbook Registered Discard" as discards
  mutate(CatchCategory = ifelse(Catch.Cat. == "Landings", 
                                "Landings", "Discards")) %>%
  #filter(CatchCategory %in% c("Discards", "Landings")) %>%
  select(year = Year, catch_category = Catch.Cat., length = Length, 
         numbers = Frequency) %>%
  group_by(year, catch_category, length) %>%
  summarise(numbers = sum(numbers)) %>%
  filter(numbers > 0)
write.taf(lngth, file = "data/length_data.csv")
saveRDS(lngth, file = "data/length_data.rds")

