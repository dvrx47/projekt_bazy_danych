#/usr/bin/python2.4
#
#

import json
import fileinput
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT


def databaseOpen(jsonData):
	try:
		global conn
		conn = psycopg2.connect( dbname   = jsonData['baza'], 
								 user     = jsonData['login'], 
								 host 	  = 'localhost',
								 password = jsonData['password']
								)
		conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)

		res['status'] = "OK"
	except:
		res['status'] = "ERROR"



def organizerFun( jsonData ):
	cur = conn.cursor()
	if jsonData['secret'] == 'd8578edf8458ce06fbc5bb76a58c5ca4':
		try:
			cur.execute("create user "+jsonData['newlogin']+
						" with password '"+jsonData['newpassword']+
						"'")
			res['status'] = "OK"
		except:
			res['status'] = "ERROR"
	else:
		res['status'] = "ERROR"


env = { 'open' : databaseOpen,
		'organizer' : organizerFun}

for json_data in fileinput.input():

	data = json.loads(json_data)

	res = json.loads( '{ "status" : ""}' )

	kontrola = True
	try:
		funkcja = env[ data.keys() [0] ]
		
	except:
		res['status'] = "NOT IMPLEMENTED"
		kontrola = False
	
	if kontrola :
		funkcja( data[ data.keys()[0] ] )

	print res
