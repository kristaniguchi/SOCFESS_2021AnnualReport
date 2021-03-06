#SOC FESS Level 1: Alteration assessment for all subbasins modeled in LSCP (Laguna Canyon, Aliso Creek, Oso Creek, Salt Creek, Horno Creek, Prima Deshecha Creek, and Segunda Deshecha Creek)
#This code loops takes the alteration assessment summary table and generates alteration maps for each FFM, synthesis alteration across flow components
#Source code for Figures 7, 10, and 11 in main text of progress report SOC FESS

#################################################

#install packages - only need to do this once
#install.packages("ggsn")
#install.packages("ggmap")
#install.packages("mapview")
#install.packages("geosphere")
#install.packages("rgeos")

#to install spDataLarge
  #install.packages("devtools")
  #library(devtools)
  #install.packages("spDataLarge")
  #install.packages("spDataLarge", repos = "https://nowosad.github.io/drat/", type = "source")
  #devtools::install_github("robinlovelace/geocompr")

#load libraries
library(spData)
library(spDataLarge)
library(dplyr)
library(tidyverse)
library(ggplot2)
library(readxl)
library(sf)
library(ggsn)
library(ggmap)
library(mapview)
library(spData)      
library(spDataLarge)
library(ggspatial)    
library(geosphere)
library(rgeos)

#################################################
#set up directories and load in data

#alteration directory - put in your folder directory that contain the alteration summary table
alteration.dir <- "L:/San Juan WQIP_KTQ/Data/RawData/From_Geosyntec/South_OC_Flow_Ecology_for_SCCWRP/KTQ_flowalteration_assessment/Oso_SmallCreeks/"

#read in component alteration data
fname = paste0(alteration.dir, "summary_component_alteration.csv") #full filename of the summary component alteration dataset
comp_alt <- read.csv(fname)

#create New_Name column with subbasin id to match polygon layer
comp_alt$New_Name <- comp_alt$subbasin

#set levels for flow component so it goes in sequence of seasons that occur in water year (WY)
comp_alt$flow_component <- factor(comp_alt$flow_component, levels = c("Fall pulse flow", "Wet-season base flow", "Peak flow", "Spring recession flow", "Dry-season base flow"))

#subbasin polygon shapefile - read in the subbasin shapefile saved here: https://ocgov.box.com/s/7likwoezsqrmnwfqd7rs24uu5mrdyitj, update path where you save shapefiles
basins <- st_read("C:/Users/KristineT/SCCWRP/SOC WQIP - Flow Ecology Study - General/Data_Products/AnnualReport_2020/Flow Ecology Level 1/Subbasin Shapefiles/Subbasin Boundaries/Subbasins_Boundaries_Source.shp", quiet = T)
#add in matching column to join with component alteration
basins$New_Name <- basins$Subbasin

#join shapefile with component alteration 
basins2 <- basins %>% 
  inner_join(comp_alt, by = c('New_Name'))
basins2

#reach polylines shapefile can be downloaded here: https://ocgov.box.com/s/rni13od1uai7r351xrt1qbp13wg0sd5o (Reach_Shapefile.zip), unzip and save on local computer, update directory below
reaches <- st_read('L:/San Juan WQIP_KTQ/Data/SpatialData/Model_Subbasins_Reaches/New_Subbasins_forSCCWRP_12062019/New_Subbasins_forSCCWRP/reaches_forSCCWRP.shp', quiet = T)

#join component alteration data frame with subbasin shapefile information
comp_alt <- comp_alt %>% 
  inner_join(basins, by = c('New_Name'))
comp_alt

#read in model source LSPC or Wildermuth - saved in GitHub repository
source <- read.csv("C:/Users/KristineT/Documents/Git/SOCFESS_2021AnnualReport/Subbasins_inmodel_source.csv")

#read in alteration summary table - all metrics --> this csv can be downloaded here: https://ocgov.box.com/s/1kw5lps4f8z058xcpg3z5306sys1rq8w 
data <- read.csv(file=paste0(alteration.dir, "ffm_alteration.df.overall.join.Aliso.Oso.SmallCreeks.csv"))
#create New_Name column with subbasin id to match polygon layer
data$New_Name <- data$subbasin
#set levels for flow component so it goes in sequence of WY
data$flow_component <- factor(data$flow_component, levels = c("Fall pulse flow", "Wet-season base flow", "Peak flow", "Spring recession flow", "Dry-season base flow"))


#################################################
# Figure 7 in main report: study area map highlighting LSPC model domain: analysis focus for phase I

#whole SOC study area map
study <- ggplot(basins) + 
  geom_sf(color = "#969696", fill="#d9d9d9") +
  labs(x ="", y = "") + 
  annotation_scale() +
  annotation_north_arrow(pad_y = unit(0.9, "cm"),  height = unit(.8, "cm"),
                         width = unit(.8, "cm")) +
  theme(panel.background = element_rect(fill = "white"),
        axis.ticks = element_blank(),
        axis.text = element_blank(),
        panel.grid = element_line(color = "white", size = 0.8))

#highlight study domain LSPC model
domain <- study + geom_sf(data = basins2, color = "red", fill="white", size = 1.2) +
  labs(title="Study Domain for Flow Ecology Analysis",subtitle = "LSPC Model Domain", x ="", y = "") +
geom_sf(data = reaches, color = "#67a9cf", size = 0.5) 

#save study area domain map, update to directory where you want to save study area map
ggsave(domain, file= "C:/Users/KristineT/Documents/Git/SOC_FESS/study_domain.jpg", dpi=400, height=6, width=8)

########################################################
#FFM alteration maps
#code to produce maps that are saved at: https://ocgov.box.com/s/icfkx7rqwntaj0i4zkr7vuyxdh6s51kd (FFM Alteration Maps.zip)

#subbasin polygons
data$New_Name <- data$subbasin
basins4 <- basins %>% 
  inner_join(data, by = c('New_Name'))
basins4

#inner join with model source
basins4 <- basins4 %>% 
  inner_join(source, by = c('New_Name')) 
basins4
#rename Source.x to Source
basins4$Source <- basins4$Source.x

#replace alteration category names
basins4$alteration.status[basins4$alteration.status == "likely_altered"] <- "Likely Altered"
basins4$alteration.status[basins4$alteration.status == "likely_unaltered"] <- "Likely Unaltered"
basins4$alteration.status[basins4$alteration.status == "indeterminate"] <- "Indeterminate"
basins4$alteration.status[basins4$alteration.status == "not_enough_data"] <- "NA"

#replace alteration direction names
basins4$alteration.direction[basins4$alteration.direction == "none_found"] <- ""
basins4$alteration.direction[which(is.na(basins4$alteration.direction))] <- ""
basins4$alteration.direction[basins4$alteration.direction == "undeterminable"] <- ""
basins4$alteration.direction[basins4$alteration.direction == "low"] <- " Low"
basins4$alteration.direction[basins4$alteration.direction == "early"] <- " Low"
basins4$alteration.direction[basins4$alteration.direction == "late"] <- " High"
basins4$alteration.direction[basins4$alteration.direction == "high"] <- " High"
#create new alteration category with direction
basins4$alteration.status.new <- paste0(basins4$alteration.status, basins4$alteration.direction)
#replace indeterminate high and low
basins4$alteration.status.new <- gsub("Indeterminate High", "Indeterminate", basins4$alteration.status.new)
basins4$alteration.status.new <- gsub("Indeterminate Low", "Indeterminate", basins4$alteration.status.new)
unique(basins4$alteration.status.new)


#list of colors and alteration statuses, color current by alteration status
colors <- c("#cb181d", "#fdbe85", "#2171b5", "#f7f7f7", "#d9d9d9")
alteration.status.new <- c("Likely Altered High", "Likely Altered Low", "Likely Unaltered", "Indeterminate", "NA")
lookup <- data.frame(cbind(colors, alteration.status.new))

#output director for alteration maps FFMs
dir.alt <- paste0(alteration.dir, "AlterationMaps/")
#create output directory if it doesn't already exist
dir.create(dir.alt)

#loop through each metric and plot alteration
unique.ffm <- unique(basins4$ffm)

for(j in 1:length(unique.ffm)){
  #subset basins4 to ffm j
  basins4.sub <- basins4[basins4$ffm == unique.ffm[j],]
  
  #subset colors and status
  lookup.sub <- lookup[lookup$alteration.status.new %in% basins4.sub$alteration.status.new,]
  
  #save alteration status as factor for legend order
  lookup.sub$alteration.status.new <- factor(lookup.sub$alteration.status.new, levels = lookup.sub$alteration.status.new)
  basins4.sub$alteration.status.new <- factor(basins4.sub$alteration.status.new, levels = lookup.sub$alteration.status.new)
  
  #find and replace names for timing low early, high late
  if(unique(basins4.sub$flow_characteristic) == "Timing (date)"){
    basins4.sub$alteration.status.new <- gsub("Likely Altered Low", "Likely Altered Early", basins4.sub$alteration.status.new)
    basins4.sub$alteration.status.new <- gsub("Likely Altered High", "Likely Altered Late", basins4.sub$alteration.status.new)
    lookup.sub$alteration.status.new <- gsub("Likely Altered Low", "Likely Altered Early", lookup.sub$alteration.status.new)
    lookup.sub$alteration.status.new <- gsub("Likely Altered High", "Likely Altered Late", lookup.sub$alteration.status.new)
  }
  unique(basins4.sub$alteration.status.new)
  
  #base map 
  study2 <- ggplot(basins) + 
    geom_sf(color = "#969696", fill="#d9d9d9") +
    labs(title=unique(basins4.sub$title_name),x ="", y = "") + 
    annotation_scale() +
    annotation_north_arrow(pad_y = unit(0.9, "cm"),  height = unit(.8, "cm"),
                           width = unit(.8, "cm")) +
    theme(panel.background = element_rect(fill = "white"),
          axis.ticks = element_blank(),
          axis.text = element_blank(),
          panel.grid = element_line(color = "white", size = 0.8))
  
  #filled alteration plots
  alt.plot <- study2 + geom_sf(data = basins4.sub, color= "#969696", aes(fill=alteration.status.new)) +
    scale_fill_manual(name = "Alteration Status", labels = lookup.sub$alteration.status.new, values=lookup.sub$colors) +
    geom_sf(data = reaches, color = "#67a9cf", size = 0.5) 
  
  #add in model source
  alt.plot <- alt.plot + geom_sf(data = basins4.sub, size = 1, fill = NA, aes(color=Source)) +
    scale_color_manual(name = "Model Source", labels = c("LSPC", "GSFLOW"), values=c("black", "hotpink")) +
    geom_sf(data = reaches, color = "#67a9cf", size = 0.5) 
  
  #print
 # print(alt.plot)
  
  #write plot
  #save as jpg
  plot.fname <- paste0(dir.alt,unique(basins4.sub$ffm), "_alteration.map.jpg")
  ggsave(alt.plot, file=plot.fname, dpi=300, height=8, width=12)
  
}


#############################################################################
#FFM maps but facet by flow component
#code to produce maps that are saved at: https://ocgov.box.com/s/icfkx7rqwntaj0i4zkr7vuyxdh6s51kd (Facet Maps by Flow Component.zip)

#loop through each component and plot panel plots of the metrics
uniq.comp <- unique(basins4$flow_component)

for(k in 1:length(uniq.comp)){
  #subset basins4 to ffm j
  basins4.sub <- basins4[basins4$flow_component == uniq.comp[k],]
  
  #subset colors and status
  lookup.sub <- lookup[lookup$alteration.status.new %in% basins4.sub$alteration.status.new,]
  #save as factor
  lookup.sub$alteration.status.new <- factor(lookup.sub$alteration.status.new, levels = unique(lookup.sub$alteration.status.new))
  basins4.sub$alteration.status.new <- factor(basins4.sub$alteration.status.new, levels = unique(lookup.sub$alteration.status.new))
  #title metric needs to be sorted, factor
  basins4.sub$title_ffm <- factor(basins4.sub$title_ffm, levels = unique(basins4.sub$title_ffm))
  
  
  #if peak flow mag, use 3 columns
  if(uniq.comp[k] == "Peak flow"){
    col.num <- 3
    font.size <- 12
  }else{
    col.num <- 2
    font.size <- 14
  }
  
  #base map 
  study2 <- ggplot(basins) + 
    #geom_sf(color = "#969696", fill="#fdbe85") +
    geom_sf(color = "#969696", fill="#d9d9d9") +
    annotation_scale() +
    annotation_north_arrow(pad_y = unit(0.9, "cm"),  height = unit(.8, "cm"),
                           width = unit(.8, "cm")) +
    labs(title=unique(basins4.sub$title_component),x ="", y = "")  + 
    theme(panel.background = element_rect(fill = "white"),
          axis.ticks = element_blank(),
          axis.text = element_blank(),
          panel.grid = element_line(color = "white", size = 0.8),
          plot.title = element_text(size=20))
  
  #filled alteration plots
  alt.plot <- study2 + geom_sf(data = basins4.sub, color= "#969696", aes(fill=alteration.status.new)) +
    scale_fill_manual(name = "Alteration Status", labels = lookup.sub$alteration.status.new, values=lookup.sub$colors) +
    facet_wrap(~ title_ffm, ncol = col.num) +
    theme(strip.text.x = element_text(size = font.size)) +
    geom_sf(data = reaches, color = "#67a9cf", size = 0.5) 
  
  #add in model source
  alt.plot <- alt.plot + geom_sf(data = basins4.sub, size = 1, fill = NA, aes(color=Source)) +
    scale_color_manual(name = "Model Source", labels = c("LSPC", "GSFLOW"), values=c("black", "hotpink")) +
    geom_sf(data = reaches, color = "#67a9cf", size = 0.5) 
  
  #print
  #print(alt.plot)
  
  #write plot
  #save as jpg
  plot.fname <- paste0(dir.alt,unique(basins4.sub$flow_component), "_alteration.map.jpg")
  ggsave(alt.plot, file=plot.fname, dpi=300, height=8, width=10)
  
}

#################################################
#Figure 10 in main text
#Heatmap of alteration: component vs. flow characteristics

#install packages
#install.packages("ztable")
library(ztable)
#if(!require(devtools)) install.packages("devtools")
#devtools::install_github("cardiomoon/ztable")
#install.packages("moonBook")
require(moonBook)

#subset to summary alteration table to altered only
altered <- data[data$alteration.status == "likely_altered",]
#remove NA
altered <- altered[-which(is.na(altered$subbasin)),]

#subset so if there is one altered characteristic per component (remove duplicates from one subbasin so we get number of subbasins with altered flow characteristics)
unique.altered.sites <- unique(altered$subbasin.model)
#create empty df that will be filled
altered.new <- altered[1,]
#fill with NA for first row to be removed later
altered.new[1,] <- NA
altered.new$comp.characteristic <- NA

#loop through each site and create one alteration category per component to create new dataframe altered.new

for(i in 1:length(unique.altered.sites)){
  sub1 <- altered[altered$subbasin.model == unique.altered.sites[i],]
  #create vector component_characteristics in sub1
  sub1$comp.characteristic <- paste0(sub1$flow_characteristic, "_", sub1$flow_component)
  #remove duplicated rows based on comp.characteristic but keep only unique/distinct rows from a data frame
  sub1 <- sub1 %>% dplyr::distinct(flow_characteristic,flow_component,  .keep_all = TRUE)
  #save sub1 into new df
  altered.new <- rbind(altered.new, sub1)
}
#remove first NA row
altered.new <- altered.new[2:length(altered.new$subbasin),]

#calculate number in each category
ffm_summary <- data.frame(aggregate(altered.new, by = altered.new[c('flow_characteristic', 'flow_component')], length))


#create table for heatmap
dev.off()
mine.heatmap <- ggplot(data = ffm_summary, mapping = aes(x = flow_characteristic,
                                                         y = factor(flow_component, levels =  c("Fall pulse flow", "Wet-season base flow", "Peak flow", "Spring recession flow", "Dry-season base flow")),
                                                         fill = subbasin)) +
  geom_tile() +
  ylab(label = "Flow Component") + xlab(label="Hydrograph Element") +
  scale_fill_gradient(name = "Number of\nAltered Subbasins",
                      low = "#fef0d9",
                      high = "#b30000") +
  ggtitle(label = "Altered Subbasins in Aliso, Oso, and Smaller Coastal Tributaries") + theme_light() +
  theme(axis.text=element_text(size=12),
        axis.title=element_text(size=14,face="bold"))

mine.heatmap

ggsave(mine.heatmap, file="C:/Users/KristineT/Documents/Git/SOC_FESS/heatmap_alteration.jpg", dpi=300, height=8, width=12)

#updated heatmap without frequency or ROC used for illustrative purposes in annual report 2020/2021
#find Frequency and Rate of change (%)
freq.ind <- grep("Frequency", ffm_summary$flow_characteristic)
roc.ind <- grep("Rate of change", ffm_summary$flow_characteristic)
#remove freq and ROC from heatmap
ffm_summary2 <- ffm_summary[-c(freq.ind, roc.ind),]

mine.heatmap2 <- ggplot(data = ffm_summary2, mapping = aes(x = flow_characteristic,
                                                           y = factor(flow_component, levels =  c("Fall pulse flow", "Wet-season base flow", "Peak flow", "Spring recession flow", "Dry-season base flow")),
                                                           fill = subbasin)) +
  geom_tile() +
  ylab(label = "Flow Component") + xlab(label="Hydrograph Element") +
  scale_fill_gradient(name = "Number of\nAltered Subbasins",
                      low = "#fef0d9",
                      high = "#b30000") +
  ggtitle(label = "Altered Subbasins in Aliso, Oso, and Smaller Coastal Tributaries") + theme_light() +
  theme(axis.text=element_text(size=12),
        axis.title=element_text(size=14,face="bold")) 
#view heatmap
mine.heatmap2

#save heatmap
ggsave(mine.heatmap2, file="C:/Users/KristineT/Documents/Git/SOC_FESS/heatmap_alteration.nofreqROC.jpg", dpi=400, height=8, width=10)


#####################################################
#Figure 11 in main text
#Synthesis map for alteration across wet season (including baseflow and peak) and dry season

#subset component alteration data to wet, dry, peak
comp.synthesis <- c("Wet-season base flow", "Peak flow", "Dry-season base flow")
component.sub <- comp_alt[comp_alt$flow_component %in% comp.synthesis,] %>% 
  filter(component_alteration == "likely_altered") %>%
  group_by(New_Name) %>% 
  summarise(flow_component = toString(unique(flow_component))) %>% 
  ungroup() 

#save as data.frame
component.sub.df <- data.frame(component.sub)
#create new simplified categories
unique(component.sub.df$flow_component)

#get unaltered basin summary
component.sub.unaltered <- comp_alt[comp_alt$flow_component %in% comp.synthesis,] %>% 
  group_by(New_Name) %>% 
  summarise(component_alteration = toString(unique(component_alteration))) %>% 
  ungroup()
#turn to df
component.sub.unaltered.df <- data.frame(component.sub.unaltered)
#check to see if any NA (no alteration)
unique(component.sub.unaltered.df$component_alteration)

#combine with basins shapefile again
comp_alt_synth <- component.sub.df %>% 
  inner_join(basins, by = c('New_Name')) 
comp_alt_synth

#set new flow component alteration synthesis names
comp_alt_synth$flow_component <- gsub(" base flow", "", comp_alt_synth$flow_component)
comp_alt_synth$flow_component <- gsub("flow", "Flow", comp_alt_synth$flow_component)
#find unique combos that need to be updated
unique(comp_alt_synth$flow_component)
comp_alt_synth$flow_component[comp_alt_synth$flow_component == "Wet-season, Peak Flow, Dry-season"] <- "All"
#comp_alt_synth$flow_component[comp_alt_synth$flow_component == "Dry-season, Wet-season, Peak Flow"] <- "All"
#comp_alt_synth$flow_component[comp_alt_synth$flow_component == "Dry-season, Wet-season"] <- "Wet-season, Dry-season"
comp_alt_synth$flow_component[comp_alt_synth$flow_component == "Peak Flow, Dry-season"] <- "Dry-season, Peak Flow"

#check to see unique categories for synthesis alteration
unique(comp_alt_synth$flow_component)
#save as factor for legend order
comp_alt_synth$altered_components <- factor(comp_alt_synth$flow_component, levels = c("All", "Wet-season, Dry-season", "Wet-season, Peak Flow", "Dry-season, Peak Flow", "Peak Flow"))

#save colors and levels for legend/map
colors <- c("#d7191c", "#fdae61", "#2c7bb6")
levels <- c("All", "Dry-season, Peak Flow", "Peak Flow")

#base map 
study2 <- ggplot(basins) + 
  geom_sf(color = "lightgrey", fill="white") +
  #geom_sf(color = "#969696", fill="white") +
  labs(title="Hydrologic Alteration Synthesis", subtitle = "Wet and Dry Season Base-flow, Peak Flow",x ="", y = "")  + 
  annotation_scale() +
  annotation_north_arrow(pad_y = unit(0.9, "cm"),  height = unit(.8, "cm"),
                         width = unit(.8, "cm")) +
  theme(panel.background = element_rect(fill = "white"),
        axis.ticks = element_blank(),
        axis.text = element_blank(),
        panel.grid = element_line(color = "white", size = 0.8),
        plot.title = element_text(size=20),
        plot.subtitle = element_text(size=12),) 
study2

#synthesis map
syn.plot <- study2 + geom_sf(data = comp_alt_synth, color= "gray89", aes(fill=altered_components, geometry = geometry)) +
  scale_fill_manual(name = "Alterated Components", labels = levels, values=colors) +
  geom_sf(data = reaches, color = "#67a9cf", size = 0.5) 

#add in model source
syn.plot2 <- syn.plot + geom_sf(data = comp_alt_synth, size = 1, fill = NA, aes(color=Source, geometry = geometry)) +
  scale_color_manual(name = "Model Source", labels = c("LSPC", "GSFLOW"), values=c("black", "hotpink")) +
  geom_sf(data = reaches, color = "#67a9cf", size = 0.5) 


#print
print(syn.plot2)

#save image
plot.fname <- paste0(dir.alt, "Synthesis_Alteration_Map_wetdrypeak.jpg")
ggsave(syn.plot, file=plot.fname, dpi=400, height=6, width=8)


