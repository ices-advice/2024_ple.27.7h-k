### ------------------------------------------------------------------------ ###
### Prepare plots and tables for report ####
### ------------------------------------------------------------------------ ###


## Before: model/advice.rds
## After:  figures in report/figures/
##         tables in report/tables

library(icesTAF)
taf.libPaths()
library(icesAdvice)
library(cat3advice)
library(ggplot2)
library(tidyr)
library(dplyr)

mkdir("report")
mkdir("report/figures")
mkdir("report/tables")

### ------------------------------------------------------------------------ ###
### load advice and catch ####
### ------------------------------------------------------------------------ ###
advice <- readRDS("model/advice.rds")
lc_annual <- readRDS("model/lc_annual.rds")
catch <- read.taf("data/advice_history.csv")

### ------------------------------------------------------------------------ ###
### rfb rule - figures ####
### ------------------------------------------------------------------------ ###

### A - reference catch
### compare realised catch to advice
catch %>%
  select(year, catch = ICES_catch, advice = ICES_advice) %>%
  pivot_longer(-year) %>%
  filter(year >= 2016) %>%
  ggplot(aes(x = year, y = value, fill = name)) +
  geom_col(position = "dodge") +
  scale_fill_discrete("") + 
  scale_x_continuous(breaks = scales::pretty_breaks()) + 
  labs(y = "Catch (tonnes)", x = "Year") +
  theme_bw(base_size = 8)
ggsave("report/figures/catch_advice.png", width = 10, height = 6, units = "cm",
       dpi = 300, type = "cairo")



### r - biomass index trend/ratio 
plot(advice@r)
ggsave("report/figures/rfb_r.png", width = 10, height = 6, units = "cm",
       dpi = 300, type = "cairo")

### b - biomass safeguard
plot(advice@b)
ggsave("report/figures/rfb_b.png", width = 10, height = 6, units = "cm",
       dpi = 300, type = "cairo")
### b & r
plot(advice@r, advice@b)
ggsave("report/figures/rfb_rb.png", width = 10, height = 6, units = "cm",
       dpi = 300, type = "cairo")

### f - length at first capture
# plot(advice@f@Lmean@Lc)
# ggsave("report/figures/rfb_Lc.png", width = 15, height = 10, units = "cm",
#        dpi = 300, type = "cairo")
### annual values
plot(lc_annual)
ggsave("report/figures/rfb_Lc_annual.png", width = 20, height = 15, units = "cm",
       dpi = 300, type = "cairo")

### f - annual length distributions
plot(advice@f@Lmean)
ggsave("report/figures/rfb_Lmean.png", width = 15, height = 10, units = "cm",
       dpi = 300, type = "cairo")

### f - length indicator
plot(advice@f)
ggsave("report/figures/rfb_f.png", width = 10, height = 6, units = "cm",
       dpi = 300, type = "cairo")
### f - inverse length indicator
plot(advice@f, inverse = TRUE)
ggsave("report/figures/rfb_f_inverse.png", width = 10, height = 6, units = "cm",
       dpi = 300, type = "cairo")

### ------------------------------------------------------------------------ ###
### rfb rule - advice table ####
### ------------------------------------------------------------------------ ###
### create ICES advice style table
### numbers are rounded following ICES rounding rules


### print to screen
advice(advice)
### save in file
capture.output(advice(advice), file = "report/tables/advice_table.txt")

