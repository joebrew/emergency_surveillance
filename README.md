# emergency_surveillance

Run python from command line supplying (in order) two arguments
Example:
python code/get_data.py 2014-08-10 2014-08-11

If no arguments are supplied, it will default to yesterday's data.

Once you have all the data in the data directory, you can run code/reporters_by_month.R to get a csv containing the number of visits by month for each hospital. 