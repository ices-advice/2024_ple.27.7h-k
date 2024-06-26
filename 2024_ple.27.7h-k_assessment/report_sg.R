### ------------------------------------------------------------------------ ###
### create ICES standard graphs for advice sheet ####
### ------------------------------------------------------------------------ ###

## Before: model/advice.rds
##         model/advice_history.rds
## After:  report/standard_graphs/ple.27.7h_k_YYYY.xml

### load packages
library(icesTAF)
library(icesSAG)
library(cat3advice)
library(dplyr)
library(tidyr)

mkdir("report/standard_graphs")

if (!exists("verbose")) verbose <- FALSE 

### ------------------------------------------------------------------------ ###
### load data ####
### ------------------------------------------------------------------------ ###
advice <- readRDS("model/advice.rds")
catch <- read.taf("data/advice_history.csv")

### ------------------------------------------------------------------------ ###
### create SAG objects ####
### ------------------------------------------------------------------------ ###
### assessment year
ass_yr <- 2024

### list of possible elements:
### https://datsu.ices.dk/web/selRep.aspx?Dataset=126
### allowed units:
### https://vocab.ices.dk/?ref=155

### set up stock info
stk_info <- stockInfo(
  StockCode = "ple.27.7h-k", 
  AssessmentYear = ass_yr, 
  ContactPerson = "claire.moore@marine.ie", 
  Purpose = "Advice",
  StockCategory = "3.2", # rfb rule, see https://vocab.ices.dk/?ref=1526
  ModelType = "None", # https://vocab.ices.dk/?ref=1524
  ModelName = "None"
)

### add some more data manually
stk_info$CustomLimitName1 <- "Itrigger" ### for biomass index plot
stk_info$CustomLimitValue1 <- advice@b@Itrigger
stk_info$CustomLimitName2 <- "Fmsy proxy" ### for length-based indicator
stk_info$CustomLimitValue2 <- 1
stk_info$StockSizeDescription <- "Biomass Index"
stk_info$StockSizeUnits <- "t" ### units: https://vocab.ices.dk/?ref=155
stk_info$ConfidenceIntervalDefinition	 <- "95%"
stk_info$CatchesLandingsUnits <- "t" ### t for tonnes
stk_info$CustomSeriesUnits1 <- "ratio"
stk_info$CustomSeriesName1 <- "Length-based Fishing Pressure Proxy"

### get and format data
df_catch <- catch %>% 
  select(Year = year, 
         Landings = ICES_landings,
         Discards = ICES_discards) %>%
  filter(!is.na(Landings))
df_idx <- advice@r@idx %>%
  select(Year = year, StockSize = index, Low_StockSize = low_stocksize  , High_StockSize = high_stocksize)

df_f <- advice@f@indicator %>%
  ungroup() %>%
  select(Year = year, CustomSeries1 = inverse_indicator)
df <- full_join(df_catch, df_idx) %>%
  full_join(df_f)

### set up data
# https://datsu.ices.dk/web/selRep.aspx?Dataset=126  # Record: AF - Fish Data
stk_data <- stockFishdata(
  Year = df$Year,
  Landings = df$Landings,
  Discards = df$Discards,
  StockSize = df$StockSize,
  Low_StockSize = df$Low_StockSize, 
  High_StockSize = df$High_StockSize, 
  CustomSeries1 = df$CustomSeries1
)

### save as XML file
xmlfile <- createSAGxml(stk_info, stk_data)
writeLines(xmlfile, paste0("report/standard_graphs/ple.27.7h-k_", ass_yr, ".xml"))
### this file can be manually uploaded at 
### https://standardgraphs.ices.dk/manage/index.aspx
### Alternatively: do it all from R (see below)


### ------------------------------------------------------------------------ ###
### automatic upload of data and configuration of plots/data ####
### ------------------------------------------------------------------------ ###

### ICES standard graphs
### create token for authentication
### go to https://standardgraphs.ices.dk/manage/index.aspx
### login
### click on create token or go directly to 
### https://standardgraphs.ices.dk/manage/CreateToken.aspx
### create new token, save in file
# file.edit("~/.Renviron")
### in the format 
### SG_PAT=some_token_......
### save and restart R

if (isTRUE(verbose)) {
  
  ### load token
  Sys.getenv("SG_PAT")
  options(icesSAG.use_token = TRUE)

  ## check assessments keys
  key <- findAssessmentKey("ple.27.7h-k", year = ass_yr)
  key_last <- findAssessmentKey("ple.27.7h-k", year = ass_yr - 2) ### biennial
  
  ### last year's graphs
  # plot(getSAGGraphs(key_last))
  ### doesn't work ... error 404
  
  ### last year's graphs
  # settings_last <- getSAGSettingsForAStock(key_last)
  
  ### upload 
  key_new <- uploadStock(info = stk_info, fishdata = stk_data, verbose = TRUE)
  ### key_new <- 1881
  # findAssessmentKey('ple.27.7e', ass_yr, full = TRUE)$AssessmentKey
  
  ### plots and settings not working properly...
  #icesSAG:::plot.ices_standardgraph_list(getSpawningStockBiomassGraph(key_new))
  ### return a plot with text "is not published yet"...
  
  # ### check upload
  # windows() ### RStudio's interal plot pane causes RStudio to crash...
  # plot(getSAGGraphs(key_new))
  # 
  # ### get chart settings 
  # ### should be automatically copied from last year
  # chart_settings <- getSAGSettingsForAStock(key_new) 
  # 
  # plot(getLandingsGraph(key_new))
  # 
  # ### compare with last years settings
  # settings_last <- getSAGSettingsForAStock(key_last)
  # all.equal(chart_settings, settings_last)
  # ### yes, identical (only new assessment key)
  
  ### modify chart settings
  ### possible options listed here: 
  ### https://standardgraphs.ices.dk/manage/ListSettings.aspx
  
  # ### check again
  # getSAGSettingsForAStock(key_new) 
  # windows()
  # plot(getSAGGraphs(key_new))
  # 

}

