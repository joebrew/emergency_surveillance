#####
# PACKAGES
#####
library(dplyr)
library(readr)

#####
# DIRECTORY ISSUES
#####
project_root <- getwd() # Open in emergency_surveillance
code_dir <- paste0(project_root, '/code')
data_dir <- paste0(project_root, '/data')

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
    
    # Group by hospital and date
    temp <- temp %>%
      group_by(date, HospitalName) %>%
      summarise(n = n())
    
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
save.image('~/Desktop/temp.RData')

#####
# CLEAN UP
#####
# Get an expanded grid version
eg <- expand.grid('date' = unique(sort(results$date)),
                  'HospitalName' = unique(sort(results$HospitalName)))
# Join eg and results, so that we have NA's for the 0s
eg <- left_join(eg, results)
# Make NA's 0s
eg$n[which(is.na(eg$n))] <- 0
# Get a month and year
eg$month <- as.numeric(format(eg$date, '%m'))
eg$year <- as.numeric(format(eg$date, '%Y'))

# Group by year-month
eg_grouped <-
  eg %>%
  group_by(year, month, HospitalName) %>%
  summarise(n = sum(n, na.rm = TRUE))

# Write the csv
setwd(data_dir)
dir.create('jonathan_results')
setwd('jonathan_results/')
write_csv(eg_grouped, 'hospital_visits_over_time.csv')

# Read csv and anonymize
eg_grouped <- read_csv('hospital_visits_over_time.csv')

# Make a boolean reported or not
eg_grouped$reported <- ifelse(eg_grouped$n > 0, 'yes', 'no')

# Slim down
eg_grouped <- eg_grouped[,c('year', 'month', 'HospitalName', 'reported', 'n')]

# Write
write_csv(eg_grouped, 'hospital_visits_over_time_anonymized.csv')
