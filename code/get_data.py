#!/usr/bin/env python
# Make executable: chmod +x test.py 

#####
#Import necessary libraries
#####
import mechanize
import cookielib
from BeautifulSoup import BeautifulSoup
import html2text
import pandas as pd
import subprocess
import os
# import rpy2
# import rpy2.robjects as robjects
import re
import time
import platform
import shutil
from datetime import datetime, timedelta
import sys

#####
# DATE OPTION FROM COMMAND LINE
#####
try:
    start_date = sys.argv[1]
    end_date = sys.argv[2]
except:
	start_date = (datetime.today() - timedelta(days=1)).strftime("%Y-%m-%d")
	end_date = start_date

# Give essence url format
start_date = datetime.strptime(start_date, '%Y-%m-%d').strftime('%d%b%Y').lower()
end_date = datetime.strptime(end_date, '%Y-%m-%d').strftime('%d%b%Y').lower()

print 'start date is ' + start_date
print 'end date is ' + end_date

#####
# Specify directories
#####
plat = platform.uname()
print 'working on a ' + plat[0] + ' ' + plat[1]
public = '/home/joebrew/Documents/emergency_surveillance'
private = public + '/data'
os.chdir(private)

#####
# LOG INTO ESSENCE SYSTEM
#####
# Browser
br = mechanize.Browser()

# Cookie Jar
cj = cookielib.LWPCookieJar()
br.set_cookiejar(cj)

# Browser options
br.set_handle_equiv(True)
br.set_handle_gzip(True)
br.set_handle_redirect(True)
br.set_handle_referer(True)
br.set_handle_robots(False)
br.set_handle_refresh(mechanize._http.HTTPRefreshProcessor(), max_time=1)

br.addheaders = [('User-agent', 'Chrome')]

# The site we will navigate into, handling it's session
br.open('https://www.essencefl.com/florida_5_1_14/servlet/Login')
#br.open('https://github.com/login')

# View available forms
#for f in br.forms():
#    print f

# Select the second (index one) form (the first form is a search query box)
br.select_form(nr=0)

# Read in credentials
os.chdir(public)
pu = pd.read_csv('credentials/pu.csv', dtype = 'string')

# Extract ESSENCE username and password from the pu file
u = list(pu['u'])[0]
p = list(pu['p'])[0]

# User credentials
br.form['j_username'] = u
br.form['j_password'] = p

# Login
br.submit()


####################################
# DAY BY DAY DOWNLOAD
####################################

# # Make a daterange object
dates = pd.date_range(start = datetime.strptime(start_date, '%d%b%Y'), end = datetime.strptime(end_date, '%d%b%Y')).tolist()

# Loop through each date, getting the data for that day
os.chdir(private)
for i in range(len(dates)):

    # Get the start time
    start_time = datetime.now()

    # Define (in essence url format) the day in question
    this_day = dates[i].strftime('%d%b%Y').lower()

    # Give a status
    print 'Working on ' + this_day

    # Make a filename
    file_name = this_day + '.txt'

    # Get link
    todays_link = 'https://www.essencefl.com/florida_5_1_14/servlet/PlainDataDetailsServlet?ageCDCILI=all&startDate=' + this_day + '&medicalGroupingSystem=essencesyndromes&initPulseOx=all&sex=all&geographySystem=hospitalregion&predomRace=all&dom=all&patientClass=all&timeResolution=daily&doy=all&censusRaceBlackPercGroup=all&endDate=' + this_day + '&dow=all&clinicalImpression=all&detector=probrepswitch&ageTenYear=all&geography=all&patientLoc=all&age=all&dischargeDiagnosis=all&year=all&medicalSubGrouping=all&datasource=va_hosp&censusRaceAsianPercGroup=all&percentParam=noPercent&medicalGrouping=all&timeInterval=all&aqtTarget=datadetails&hospitalGrouping=all&agerange=all&censusRaceHawaiianPercGroup=all&ccddFreeText=all&predomHispanic=all&initTemp=all&diagnosisType=all&censusRaceAmerIndPercGroup=all&dispositionCategory=all&medianIncomeGroup=all&agedistribute=all&month=all&ccddCategory=all&censusRaceOtherPercGroup=all&hospFacilityType=all&censusRaceWhitePercGroup=all&week=all&quarter=all'

    # READ AND WRITE THE DATA
    my_file = br.open(todays_link)
    # Write a text file
    f = open(file_name, 'w')
    f.write(my_file.read())
    f.close()

    # Give a status
    print 'Done with ' + this_day

    # Get the end time
    end_time = datetime.now()

    # Print how long it took
    print 'That day took ' + str(round((end_time - start_time).total_seconds())) + ' seconds.'

    #


    # # Sleep
    # print 'Now sleeping 30 seconds.'
    # time.sleep(30)





# ####################################
# # FOR MULTI-DAY DOWNLOAD
# ####################################
# #####
# # GET LINK TO UPDATE DATABASE
# #####

# # NEW FILENAME
# if start_date == end_date:
# 	file_name = start_date + '.txt'
# else:
# 	file_name = start_date + '-' + end_date + '.txt'

# # LINK
# todays_link = 'https://www.essencefl.com/florida_5_1_14/servlet/PlainDataDetailsServlet?ageCDCILI=all&startDate=' + start_date + '&medicalGroupingSystem=essencesyndromes&initPulseOx=all&sex=all&geographySystem=hospitalregion&predomRace=all&dom=all&patientClass=all&timeResolution=daily&doy=all&censusRaceBlackPercGroup=all&endDate=' + end_date + '&dow=all&clinicalImpression=all&detector=probrepswitch&ageTenYear=all&geography=all&patientLoc=all&age=all&dischargeDiagnosis=all&year=all&medicalSubGrouping=all&datasource=va_hosp&censusRaceAsianPercGroup=all&percentParam=noPercent&medicalGrouping=all&timeInterval=all&aqtTarget=datadetails&hospitalGrouping=all&agerange=all&censusRaceHawaiianPercGroup=all&ccddFreeText=all&predomHispanic=all&initTemp=all&diagnosisType=all&censusRaceAmerIndPercGroup=all&dispositionCategory=all&medianIncomeGroup=all&agedistribute=all&month=all&ccddCategory=all&censusRaceOtherPercGroup=all&hospFacilityType=all&censusRaceWhitePercGroup=all&week=all&quarter=all'

# os.chdir(private)
# my_file = br.open(todays_link)
# # Write a text file
# f = open(file_name, 'w')
# f.write(my_file.read())
# f.close()