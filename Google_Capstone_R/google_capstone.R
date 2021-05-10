
## ----- install required packages, load libraries -----
install.packages("tidyverse")
install.packages("ggplot2")
install.packages("lubridate")
install.packages("ggstatsplot")

library(tidyverse)
library(lubridate)
library(ggplot2)
library(ggstatsplot)
library(ggthemes)
## ----- import the data: imported through dashboard. -----
# read_csv(".....csv") not needed. 
setwd("~/Desktop/Google Data Analysis/casestudy")
feb21 <- read.csv("feb21.csv")
colnames(feb21)

# in my case, my laptop is not able to handle large datasets 
# due to storage issues, hence I work with Feb 2021 dataset. 
# if there were more than one tables, I would:
# 1. make the columns of different tables consistent. 
# 2. Rename them, consistent data types using mutate
# 3. stack the data using bind_rows. 

## ----- prepare for analysis & clean the data -----
dim(feb21)
head(feb21)
tail(feb21)
str(feb21)
summary(feb21)
na.omit(feb21) # goes from 49k to 42k. have not
# assigned to the dataframe yet. 

unique(feb21$member_casual)#check for unique values
# only 2 values in the column, which is good. 
table(feb21$member_casual)#checknumber of obs.
# additional column: day of the week and ride duration
# have been added using Google Sheets. 

# add another column with ride duration in seconds
feb21$seconds <- difftime(feb21$ended_at, feb21$started_at)
str(feb21$seconds) #it is already numeric, no need to convert

nrow(feb21[feb21$seconds<0,]) #checking for negative values
nrow(feb21[feb21$seconds == 0,]) # 4 values with 0 duration
nrow(feb21[feb21$start_station_name == "HQ QR",])
#above bikes were taken out of docks and checked for quality
#they should be taken out. 
# we subset our dataset where station name was HQ QR or if trip duration was 0. 
feb21mod <- feb21[!(feb21$start_station_name == "HQ QR" | feb21$seconds == 0),]
sum(is.na(feb21mod$seconds))

##----- Descriptive Stats -----
mean(feb21mod$seconds, na.rm = TRUE)
median(feb21mod$seconds, na.rm = TRUE)
max(feb21mod$seconds, na.rm = TRUE)
min(feb21mod$seconds, na.rm = TRUE)
# the mean is very far from median, this is often the case with 
# mean, which is skewed by extreme values. 
summary(feb21mod$seconds, na.rm = TRUE)
# take note of the outliers. 
quan_tile <- quantile(feb21mod$seconds, probs=c(.25, .75), na.rm = TRUE)
iqr <- IQR(feb21mod$seconds, na.rm=TRUE)
uprange <- quan_tile[2]+1.5*iqr
lowrange <- quan_tile[1]-1.5*iqr
print(quan_tile)
print(uprange)
print(lowrange)
feb21inrange <- subset(feb21mod, feb21mod$seconds > (quan_tile[1] - 1.5*iqr) 
                       & feb21mod$seconds < (quan_tile[2]+1.5*iqr))
# new dataset only contains data excluding extreme values
# skewing the dataset. 

mean(feb21inrange$seconds, na.rm = TRUE)
median(feb21inrange$seconds, na.rm = TRUE)
max(feb21inrange$seconds, na.rm = TRUE)
min(feb21inrange$seconds, na.rm = TRUE)
# now the mean is much closer to the median. 

# start comparing the different users. 
aggregate(feb21inrange$seconds ~ feb21inrange$member_casual, FUN = mean, na.rm = TRUE)
aggregate(feb21inrange$seconds ~ feb21inrange$member_casual, FUN = median, na.rm = TRUE)
aggregate(feb21inrange$seconds ~ feb21inrange$member_casual, FUN = max, na.rm = TRUE)
aggregate(feb21inrange$seconds ~ feb21inrange$member_casual, FUN = min, na.rm = TRUE)

# name the days of week replacing numbers to actual day names.
feb21inrange$day_of_week <- recode(feb21inrange$day_of_week, "1"="Sunday", "2"="Monday",
                                   "3"="Tuesday",
                                   "4"="Wednesday",
                                   "5"="Thursday",
                                   "6"="Friday",
                                   "7"="Saturday")

# additionally breaking it down by day
aggregate(feb21inrange$seconds ~ feb21inrange$member_casual + feb21inrange$day_of_week, FUN = mean)

# analyze by type and weekday
feb21inrange %>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>%  #creates weekday field using wday()
  group_by(member_casual, weekday) %>%  #groups by usertype and weekday
  summarise(number_of_rides = n()                            #calculates the number of rides and average duration 
            ,average_duration = mean(seconds)) %>%         # calculates the average duration
  arrange(member_casual, weekday)                                # sorts

# visualize the number of rides by rider type
feb21inrange %>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>% 
  group_by(member_casual, weekday) %>% 
  summarise(number_of_rides = n()
            ,average_duration = mean(seconds())) %>% 
  arrange(member_casual, weekday)  %>% 
  ggplot(aes(x = weekday, y = number_of_rides, fill = member_casual)) +
  geom_col(position = "dodge") + theme_wsj() + ggtitle("Number of Rides") +
  labs(fill = "User type") + theme(plot.title = element_text(hjust = 0.5))

# visualization for average duration
feb21inrange %>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>% 
  group_by(member_casual, weekday) %>% 
  summarise(number_of_rides = n()
            ,average_duration = mean(seconds)) %>% 
  arrange(member_casual, weekday)  %>% 
  ggplot(aes(x = weekday, y = average_duration, fill = member_casual)) +
  geom_col(position = "dodge") + theme_wsj() +
  theme_wsj() + ggtitle("Average Ride Duration(sec)") +
  labs(fill = "User type") + theme(plot.title = element_text(hjust = 0.5))

write.csv(feb21inrange,'monthbikes.csv')

