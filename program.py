import json
import fileinput
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT


def databaseOpen(jsonData):
	try:
		global conn
		global bazaDanych
		bazaDanych = jsonData['baza']
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
			cur.execute("insert into uzytkownik( login, password ) values ('"+
							 jsonData['newlogin']+"', '"+jsonData['newpassword']+"');")
			res['status'] = "OK"
			try:
				cur.execute("grant organizator to "+jsonData['newlogin']+";")
			except:
				cur.execute("drop user "+jsonData['newlogin']+";")
				res['status'] = "ERROR"
				
		except:
			res['status'] = "ERROR"
	else:
		res['status'] = "ERROR"
		

def eventFun( jsonData ):
	try:
		newConn =  psycopg2.connect( dbname   = bazaDanych, 
									 user     = jsonData['login'], 
									 host 	  = 'localhost',
									 password = jsonData['password']
									)
		newConn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
		
		cur = newConn.cursor()
		cur.execute("insert into wydarzenie(wydarzenie_nazwa, startdate, enddate) values ('"+
					jsonData['eventname']+"', '"+jsonData['start_timestamp']+"', '"+jsonData['end_timestamp']+"');") 
		newConn.close()
		
		res['status'] = "OK"
	except:
		res['status'] = "ERROR"
		

def userFun( jsonData ):
	try:
		newConn =  psycopg2.connect( dbname   = bazaDanych, 
									 user     = jsonData['login'], 
									 host 	  = 'localhost',
									 password = jsonData['password']
									)
		newConn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
		
		cur = newConn.cursor()
		cur.execute("insert into uzytkownik( login, password ) values ('"+
					jsonData['newlogin']+"', '"+jsonData['newpassword']+"');")
		newConn.close()
		
		res['status'] = "OK"
	except:
		res['status'] = "ERROR"
		
		
def register_user_for_eventFun(jsonData):
	try:
		newConn =  psycopg2.connect( dbname   = bazaDanych, 
									 user     = jsonData['login'], 
									 host 	  = 'localhost',
									 password = jsonData['password']
									)
		newConn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
		
		cur = newConn.cursor()
		cur.execute("select * from zapisz_na_wydarzenie('"+ jsonData['login'] +"', '"+jsonData['eventname']+"');" )
		newConn.close()
		
		res['status'] = "OK"
	except:
		res['status'] = "ERROR"
		
		
def talkFun( jsonData ):
	try:
		newConn =  psycopg2.connect( dbname   = bazaDanych, 
									 user     = jsonData['login'], 
									 host 	  = 'localhost',
									 password = jsonData['password']
									)
		newConn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
		
		cur = newConn.cursor()
		cur.execute("select * from utworz_wydarzenie('"+ 
					 jsonData['speakerlogin'] +"', '"+jsonData['talk']+"', '"+jsonData['title']+"', '"+jsonData['start_timestamp']+"', "+
					 jsonData['room']+", "+ jsonData['initial_evaluation'] + ", '"+ jsonData['eventname'] + "', '" + jsonData['login'] + "');" )
		newConn.close()
		
		res['status'] = "OK"
	except:
		res['status'] = "ERROR"
		
		
def attendanceFun( jsonData ):
	try:
		newConn =  psycopg2.connect( dbname   = bazaDanych, 
									 user     = jsonData['login'], 
									 host 	  = 'localhost',
									 password = jsonData['password']
									)
		newConn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
		
		cur = newConn.cursor()
		cur.execute("select * from potwierdz_obecnosc('"+jsonData['login']+"', '"+jsonData['talk'] + "');")
		newConn.close()
		
		res['status'] = "OK"
	except:
		res['status'] = "ERROR"
		
def evaluationFun( jsonData ):
	try:
		newConn =  psycopg2.connect( dbname   = bazaDanych, 
									 user     = jsonData['login'], 
									 host 	  = 'localhost',
									 password = jsonData['password']
									)
		newConn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
		
		cur = newConn.cursor()
		cur.execute("select * from ocen_referat('"+jsonData['login']+"', '"+jsonData['talk'] + "', " + str(jsonData['rating']) + ");")
		newConn.close()
		
		res['status'] = "OK"
	except:
		res['status'] = "ERROR"
		
def friendFun( jsonData ):
	try:
		newConn =  psycopg2.connect( dbname   = bazaDanych, 
									 user     = jsonData['login1'], 
									 host 	  = 'localhost',
									 password = jsonData['password']
									)
		newConn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
		
		cur = newConn.cursor()
		cur.execute("select * from zawrzyj_znajomosc('"+ jsonData['login1'] + "', '" +jsonData['login2'] + "');")
		newConn.close()
		
		res['status'] = "OK"
	except:
		res['status'] = "ERROR"
		
		
def rejectFun( jsonData ):
	try:
		newConn =  psycopg2.connect( dbname   = bazaDanych, 
									 user     = jsonData['login'], 
									 host 	  = 'localhost',
									 password = jsonData['password']
									)
		newConn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
		
		cur = newConn.cursor()
		cur.execute("delete from propozycja_referat where nazwa = '" +jsonData['title']+ "';")
		newConn.close()
		
		res['status'] = "OK"
	except:
		res['status'] = "ERROR"
		

def user_planFun( jsonData ):
	try:
		cur = conn.cursor()
		cur.execute("select * from plan('" + jsonData['login'] + "', " + str( jsonData['limit'] ) + ");")
		data = cur.fetchall()
		lista = []
		for nazwa, tytul, startDate, sala in data:
			podlista = {}
			podlista['login'] 				= jsonData['login']
			podlista['talk'] 				= nazwa
			podlista['title'] 				= tytul
			podlista['start_timestamp'] 	= startDate.strftime("%Y-%m-%d %H:%M:%S")
			podlista['room'] 				= str(sala)
			lista.append( json.dumps(podlista, ensure_ascii=False)  )
		
		res['status'] = "OK"
		res['data'] = lista
	except:
		res['status'] = "ERROR"
		
		
def day_planFun( jsonData ):
	try:
		cur = conn.cursor()
		cur.execute("select * from day_plan('" + jsonData['timestamp']+  "');")
		data = cur.fetchall()
		lista = []
		for nazwa, tytul, startDate, sala in data:
			podlista = {}
			podlista['talk'] 				= nazwa
			podlista['start_timestamp'] 	= startDate.strftime("%Y-%m-%d %H:%M:%S")
			podlista['title'] 				= tytul
			podlista['room'] 				= str(sala)
			lista.append( json.dumps(podlista, ensure_ascii=False)  )
		
		res['status'] = "OK"
		res['data'] = lista
	except:
		res['status'] = "ERROR"
		
def best_talksFun( jsonData ):
	try:
		cur = conn.cursor()
		cur.execute("select * from best_talks('" + jsonData['start_timestamp']+ "', '" + jsonData['end_timestamp'] + 
					"', "+ str(jsonData['limit']) + ", " + str(jsonData['all'])+");")
		data = cur.fetchall()
		lista = []
		for nazwa, tytul, startDate, sala in data:
			podlista = {}
			podlista['talk'] 				= nazwa
			podlista['start_timestamp'] 	= startDate.strftime("%Y-%m-%d %H:%M:%S")
			podlista['title'] 				= tytul
			podlista['room'] 				= str(sala)
			lista.append( json.dumps(podlista, ensure_ascii=False)  )
		
		res['status'] = "OK"
		res['data'] = lista
	except:
		res['status'] = "ERROR"
		
		
def most_popular_talksFun( jsonData ):
	try:
		cur = conn.cursor()
		cur.execute("select * from most_popular_talks('" + jsonData['start_timestamp']+ "', '" + jsonData['end_timestamp'] + 
					"', "+ str(jsonData['limit']) +");")
		data = cur.fetchall()
		lista = []
		for nazwa, tytul, startDate, sala in data:
			podlista = {}
			podlista['talk'] 				= nazwa
			podlista['start_timestamp'] 	= startDate.strftime("%Y-%m-%d %H:%M:%S")
			podlista['title'] 				= tytul
			podlista['room'] 				= str(sala)
			lista.append( json.dumps(podlista, ensure_ascii=False)  )
		
		res['status'] = "OK"
		res['data'] = lista
	except:
		res['status'] = "ERROR"
		
		
def attended_talksFun( jsonData ):
	try:
		newConn =  psycopg2.connect( dbname   = bazaDanych, 
									 user     = jsonData['login'], 
									 host 	  = 'localhost',
									 password = jsonData['password']
									)
		newConn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
		
		cur = newConn.cursor()
		
		cur.execute("select * from attended_talks('" + jsonData['login']+ "');") 
		
		data = cur.fetchall()
		lista = []
		for nazwa, tytul, startDate, sala in data:
			podlista = {}
			podlista['talk'] 				= nazwa
			podlista['start_timestamp'] 	= startDate.strftime("%Y-%m-%d %H:%M:%S")
			podlista['title'] 				= tytul
			podlista['room'] 				= str(sala)
			lista.append( json.dumps(podlista, ensure_ascii=False)  )
		
		newConn.close()
		
		res['status'] = "OK"
		res['data'] = lista
	except:
		res['status'] = "ERROR"
		
def abandoned_talksFun( jsonData ):
	try:
		newConn =  psycopg2.connect( dbname   = bazaDanych, 
									 user     = jsonData['login'], 
									 host 	  = 'localhost',
									 password = jsonData['password']
									)
		newConn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
		
		cur = newConn.cursor()
		
		cur.execute("select * from abandoned_talks('" + jsonData['login']+ "', " + str( jsonData['limit'] + ");") 
		
		data = cur.fetchall()
		lista = []
		for nazwa, tytul, startDate, sala, numer in data:
			podlista = {}
			podlista['talk'] 				= nazwa
			podlista['start_timestamp'] 	= startDate.strftime("%Y-%m-%d %H:%M:%S")
			podlista['title'] 				= tytul
			podlista['room'] 				= str(sala)
			podlista['number']				= str(numer)
			lista.append( json.dumps(podlista, ensure_ascii=False)  )
		
		newConn.close()
		
		res['status'] = "OK"
		res['data'] = lista
	except:
		res['status'] = "ERROR"
		


env = { 
		'open' 						: databaseOpen,
		'organizer' 				: organizerFun,
		'event' 					: eventFun,
		'user'						: userFun,
		'register_user_for_event'   : register_user_for_eventFun,
		'talk'						: talkFun,
		'attendance'				: attendanceFun,
		'evaluation'				: evaluationFun,
		'friends'					: friendFun,
		'reject'					: rejectFun, 
		'user_plan'					: user_planFun,
		'day_plan'					: day_planFun,
		'best_talks'				: best_talksFun,
		'most_popular_talks'		: most_popular_talksFun,
		'attended_talks'			: attended_talksFun,
		'abandoned_talks'			: abandoned_talksFun
	  }

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
	
	
conn.close()
