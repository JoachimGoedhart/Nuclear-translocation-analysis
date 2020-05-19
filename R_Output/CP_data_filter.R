require(dplyr)


# setwd("/Users/Sergei/Desktop/Tutorial/CP output/")
setwd("../CP_Output")
path <- getwd()

time_interval <- 4.5
radius <- 1

csv_list <- list.files(path, pattern="Nuclei.csv|Cytoplasm.csv")
# csv_list <- list.files(path, pattern="Cytoplasm.csv")


ind <- 0
for (i in csv_list){
  ind <- ind +1
  df_temp <- read.csv(i)
  # filename1 <- gsub(csv_list[ind], pattern="\\..*", replacement=".csv")
  # write.csv(df_temp, file=filename1, row.names = FALSE)
  
  #Add '_filtered' to the filename
  filename <- gsub(csv_list[ind], pattern="\\..*", replacement="_filtered.csv")
  
  #Select and rename columns of interest
  df_temp <- df_temp %>% select(Time= ImageNumber, Area= AreaShape_Area, Mean_Radius= AreaShape_MeanRadius, contains("MeanIntensity_"), contains("Math"), Object_Label= TrackObjects_Label_3)
  names(df_temp) <- gsub("Intensity_MeanIntensity_", "Intensity_", names(df_temp))

  #Filter rows with NA in Object_label column, objects that have a very thin cytoplasm and with very low/high fluorescence
  df_filtered <- df_temp %>%  filter(!is.na(Object_Label))
  
  # Remove object with average Radius of 1 or smaller 
  df_filtered <- df_filtered %>% group_by(Object_Label) %>% filter(mean(Mean_Radius) > radius)
  
  #Remove object that are too dim or too bright (outside the range 131 - 3997 of the 12 bit image)
  df_filtered <- df_filtered %>% filter(Intensity_KTR_Green>0.0020 || Intensity_KTR_Green<0.0610)
  df_filtered <- df_filtered %>% filter(Intensity_KTR_Cyan>0.0020 || Intensity_KTR_Cyan<0.0610)

  #Remove any big objects (Area larger than 100)
  df_filtered <- df_filtered %>% filter(Area>100)
  
  #Determine the number of time_points
  time_points <- length(unique(df_filtered$Time))

  #Find and select (=filter) the Objectlabels that are present at all timepoints and in different frames
  df_filtered <- df_filtered %>% group_by(Object_Label) %>% add_tally() %>% filter(n==time_points)
  df_filtered <- df_filtered %>% group_by(Object_Label) %>% filter(sum(Time)==(time_points*(time_points+1))/2)
  df_filtered$n = NULL
  df_filtered <- df_filtered %>% mutate(Time_in_min=(Time-1)*time_interval)
  df_filtered[3:7]=round(df_filtered[3:7],4)
  
  #Save the filtered CSV files
  setwd("../R_Output")
  write.csv(df_filtered,file=filename, row.names = FALSE)
  setwd("../CP_Output")
}