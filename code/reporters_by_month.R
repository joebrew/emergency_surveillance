#####
# PACKAGES
#####
library(tidyr)
library(dplyr)
library(readr)

#####
# DIRECTORY ISSUES
#####
project_root <- getwd() # Open in emergency_surveillance
code_dir <- paste0(project_root, '/code')
data_dir <- paste0(project_root, '/data')

#####
# DEFINE JONATHAN'S EXCLUSION CRITERIA
#####
bad_hospitals <- 
  readLines('exclude.txt')

exclude <- expand.grid(
  HospitalName = as.character(c(bad_hospitals, 
                                'Sacred Heart Hospital on the Gulf')),
  year = 2005:2015,
  exclude = TRUE
)

# Remove exclusion for Sacred Heart after 2009
exclude$exclude[exclude$HospitalName == 'Sacred Heart Hospital on the Gulf' &
                  exclude$year >= 2010] <- FALSE
exclude <- exclude[exclude$exclude,]

#####
# READ IN DATA
#####
setwd(data_dir)
data_files <- dir()
results_list <- list()

# Loop
for (i in 1:length(data_files)){

  # Update
  cat(paste0('Working on ', i, ' of ', length(data_files)))

  try({
  
    # Read in data for that date
    temp <- read.table(data_files[i], 
                       sep = ',', 
                       header = TRUE)
    # Clean up date
    temp$date <- as.Date(temp$Date, '%m/%d/%Y')
    # Get the actual date
    temp_date <- as.Date(gsub('.txt', '', data_files[i], fixed = TRUE),
                         format = '%d%b%Y')
    # Get year
    temp$year <- as.numeric(format(temp$date, '%Y'))
    
    # Get rid of exclude by joining to the exclude dataframe
    temp <- left_join(x = temp,
                      y = exclude)
    temp$exclude[is.na(temp$exclude)] <- FALSE
    temp <- temp[!temp$exclude,]
    
    # Create columns for ILI, Injury and GI
    temp$ILI <- grepl('ILI', temp$Category_flat)
    temp$Injury <- grepl('Injury', temp$Category_flat)
    temp$GI <- grepl('GI', temp$Category_flat)
    
    # Subset further
    temp <- 
      temp %>%
      dplyr::select(date, Age, Region, ILI, GI, Injury)
    
    # Get counts for each of the syndromes
    syndromes <- c('ILI', 'GI', 'INJURY')
    temp <- temp %>%
      gather(syndrome, value, ILI:Injury)
    
    # Get rid of non-syndromes
    temp <- temp[which(temp$value),]
    
    # Group by date, age, syndrome and county of residence
    temp <- temp %>%
      group_by(date, Age, Region, syndrome) %>%
      summarise(n = n()) %>%
      rename(age = Age,
             county_of_residence = Region)
    
    # Order by county of residence, date
    temp <- arrange(temp, syndrome, county_of_residence, date, age)
    
    # Put temp into the results list
    results_list[[i]] <- temp
    
    # Update
    cat(paste0('---done!\n'))
      
  })
}

#####
# BIND TOGETHER THE RESULTS
#####
results <- do.call('rbind', results_list)
save.image('~/Desktop/temp_by_syndrome.RData')

#####
# CLEAN UP
#####
# Get an expanded grid version
eg <- expand.grid('date' = unique(sort(results$date)),
                  'age' = unique(sort(results$age)),
                  'county_of_residence' = unique(sort(results$county_of_residence)))
# Join eg and results, so that we have NA's for the 0s
eg <- left_join(eg, results)
# Make 
setwd(data_dir)
setwd('jonathan_results/')

eg$n[which(is.na(eg$n))] <- 0
# Get a month and year
# eg$month <- as.numeric(format(eg$date, '%m'))
# eg$year <- as.numeric(format(eg$date, '%Y'))

# Write a by day csv for Jonathan
write_csv(eg, 'hospital_visits_by_day_by_age_by_residence.csv')

# # Group by year-month
# # Get a month and year
# eg$month <- as.numeric(format(eg$date, '%m'))
# eg$year <- as.numeric(format(eg$date, '%Y'))
# 
# 
# eg_grouped <-
#   eg %>%
#   group_by(year, month, age, county_of_residence) %>%
#   summarise(n = sum(n, na.rm = TRUE))
# 
# # Write the csv
# setwd(data_dir)
# dir.create('jonathan_results')
# setwd('jonathan_results/')
# write_csv(eg_grouped, 'hospital_visits_over_time.csv')
# 
# # Read csv and anonymize
# eg_grouped <- read_csv('hospital_visits_over_time.csv')
# 
# # Make a boolean reported or not
# eg_grouped$reported <- ifelse(eg_grouped$n > 0, 'yes', 'no')
# 
# # Slim down
# eg_grouped <- eg_grouped[,c('year', 'month', 'HospitalName', 'reported', 'n')]
# 
# # Write
# write_csv(eg_grouped, 'hospital_visits_over_time_anonymized.csv')
