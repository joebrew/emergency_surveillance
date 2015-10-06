import pandas as pd
import os

minimum_date = '2005-01-01'
maximum_date = '2015-10-01'

date_sequence =  pd.date_range(start=minimum_date, end=maximum_date, periods=None, freq='M')

os.chdir('/home/joebrew/Documents/emergency_surveillance/')

for dd in date_sequence:
	dd = dd.strftime("%Y-%m-%d")
	print 'doing ' + dd
	os.system("python code/get_data.py " + dd + ' ' + dd)
	print 'done with ' + dd
