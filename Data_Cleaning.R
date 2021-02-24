setwd('C:/Users/aywel/Desktop/Physics/Complex Networks/Project/Code')

library(xopen)
library(readxl)
library(readr)
library(plyr)
library(openxlsx)
library(ggplot2)
library(ggfortify)
library(dplyr)


moma_full <- read.csv('museum_modern_art_parsed.csv')

for (scan in as.numeric(as.character(moma_full[,1]))+1){
  
  urlID <- moma_full[scan,21]
  classification <- moma_full[scan,15]
  
  fix <- is.na (urlID)
  
  if ((is.na(moma_full[scan,21])) == F) {
    na.exclude(moma_full[scan,])
  }
  
  else{
    next
  }
  
}