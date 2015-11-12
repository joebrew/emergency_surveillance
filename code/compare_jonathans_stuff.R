#### READ IN JONATHAN'S DATA, 
#### GIVEN TO HIM BY AN FDOH CONTRACTOR
library(readr)
library(dplyr)
library(ggplot2)
library(ggthemes)

# Jonathan ----
jon_raw <- read_csv('data/jonathan_provided/jonathans_essence_data_request.csv')

# Get total visits
jon_agg <- jon_raw %>%
  group_by(date) %>%
  summarise(n = sum(TotalVisits))

# Joe ---
joe_raw <- read_csv('data/hospital_visits_by_day.csv')
joe_agg <- joe_raw %>% group_by(date) %>% summarise(n = sum(n))

# Plot
ggplot() +
  geom_point(data = joe_agg, aes(x = date, y = n), col = 'blue', alpha = 0.5) +
  geom_point(data = jon_agg, aes(x = date, y = n), col = 'red', alpha = 0.5) +
  theme_economist() +
  xlab('Date') +
  ylab('Visits') +
  ggtitle('Jon (red) vs Joe (blue)')
ggsave('~/Desktop/jon_vs_joe.png')

# Get difference
df <- left_join(jon_agg, joe_agg, by = 'date')
names(df) <- c('date', 'jon', 'joe')
df$dif <- df$joe - df$jon

ggplot(df, aes(x = date, y = dif)) +
  geom_line() +
  ggtitle('Difference between Jon and Joe\'s aggregations (daily visits)') +
  theme_economist() +
  ylab('Joe\'s numbers minus Jon\'s') +
  xlab('Date')
ggsave('~/Desktop/jon_vs_joe_difference.png')

# Group by year, month
jon_agg$year <- as.numeric(format(jon_agg$date, '%Y'))
jon_agg$month <- as.numeric(format(jon_agg$date, '%m'))

jon_anon <- jon_agg %>%
  group_by(year, month) %>%
  summarise(n = sum(n))

#### READ IN JOE'S DATA
#### COMPILED BY HIMSELF SCRAPING FROM ESSENCE
joe <- read_csv('data/jonathan_results/hospital_visits_over_time_anonymized.csv')

# anonymize (ie, get rid of hospital)
joe_anon <- joe %>%
  group_by(year, month) %>%
  summarise(n = sum(n))

#####
# COMBINE
#####
joe_anon$From <- 'Joe'
jon_anon$From <- 'Jon'

joe_anon$year_month <- paste0('Y', joe_anon$year, 'M', joe_anon$month)
jon_anon$year_month <- paste0('Y', jon_anon$year, 'M', jon_anon$month)


# Downsize joe to only keep those dates in jon
joe_anon <- joe_anon[joe_anon$year_month %in% jon_anon$year_month,]

combined <- rbind(joe_anon, jon_anon)
combined$date <- as.Date(paste0(combined$year, '-', combined$month, '-01'))
#####
# PLOT
#####
ggplot(data = combined, aes(x = date, y = n, group = From, color = From)) +
  # geom_point(alpha = 0.5) +
  geom_line(alpha = 0.8) +
  theme_economist() +
  xlab('Date') + 
  ylab('Visits') +
  ggtitle('Discrepancy in total visit numbers')
