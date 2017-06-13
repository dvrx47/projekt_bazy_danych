create database wspomaganie_konferencji;
\c wspomaganie_konferencji

drop table if exists wydarzenie cascade;
drop table if exists referat cascade;
drop table if exists ocena cascade;
drop table if exists znajomosc cascade;
drop table if exists znajomosc_propozycja cascade;
drop table if exists rejestracje cascade;
drop table if exists obecnosc cascade;
drop table if exists propozycja_referat cascade;
delete from uzytkownik;
drop table if exists table uzytkownik cascade;



create table wydarzenie (
	wydarzenie_id 	 serial primary key,
	wydarzenie_nazwa varchar(50) not null unique,
	startDate 		 TIMESTAMP not null default clock_timestamp(),
	endDate 		 TIMESTAMP not null default clock_timestamp()
);



create table uzytkownik (
	uzytkownik_id 	serial primary key,
	imie 			varchar(50),
	nazwisko 		varchar(50),
	login			varchar(50) not null unique,
	password		varchar(50) not null
);




create table referat (
	referat_id 		serial primary key,
	uzytkownik_id	int not null,
	nazwa			varchar(100) not null unique,
	tytul			varchar(100) not null,		
	wydarzenie_id	int not null,
	startDate 		TIMESTAMP not null default clock_timestamp(),
	sala			int not null,

	constraint fk_referat_wydarzenie foreign key (wydarzenie_id) references wydarzenie(wydarzenie_id),
	constraint fk_referat_uzytkownik foreign key (uzytkownik_id) references uzytkownik(uzytkownik_id)
);


--typ 0 to znaczy ocena uzytkownika
--typ 1 to znaczy ocena organizatora
create table ocena (
	uzytkownik_id	int not null,
	referat_id		int not null,
	ocena			int not null check ( ocena >= 0 and ocena <=10),
	typ				int not null default 0,

	constraint fk_ocena_referat foreign key (referat_id) references referat(referat_id),
	constraint fk_ocena_uzytkownik foreign key (uzytkownik_id) references uzytkownik(uzytkownik_id)
);




create table znajomosc (
	kto1_id			int not null,
	kto2_id			int not null,

	constraint fk_kto foreign key (kto1_id) references uzytkownik(uzytkownik_id),
	constraint fk_kogo foreign key (kto2_id) references uzytkownik(uzytkownik_id)
);



create table znajomosc_propozycja (
	kto1_id			int not null,
	kto2_id			int not null,

	constraint fk_kto foreign key (kto1_id) references uzytkownik(uzytkownik_id),
	constraint fk_kogo foreign key (kto2_id) references uzytkownik(uzytkownik_id)
);


create or replace function znajomosc_propozycja_ins() 
RETURNS trigger AS $$
	BEGIN
		if exists ( SELECT * from znajomosc_propozycja where kto1_id=NEW.kto2_id and kto2_id = NEW.kto1_id) then
			execute 'delete from znajomosc_propozycja where kto1_id=' || NEW.kto2_id||' and kto2_id =' || NEW.kto1_id;
			execute 'delete from znajomosc_propozycja where kto1_id=' || NEW.kto1_id||' and kto2_id =' || NEW.kto2_id;
			execute 'insert into znajomosc(kto1_id, kto2_id) values ('||NEW.kto1_id||', '||NEW.kto2_id||')';
			execute 'insert into znajomosc(kto1_id, kto2_id) values ('||NEW.kto2_id||', '||NEW.kto1_id||')';
		end if;
		return NEW;
	END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

create table rejestracje (
	uzytkownik_id	int not null,
	wydarzenie_id	int not null,
	PRIMARY KEY( uzytkownik_id, wydarzenie_id),
	
	constraint fk_rej_wyd foreign key (wydarzenie_id) references wydarzenie(wydarzenie_id),
	constraint fk_rej_uzy foreign key (uzytkownik_id) references uzytkownik(uzytkownik_id)
);



create table obecnosc (
	uzytkownik_id	int not null,
	referat_id		int not null ,

	constraint fk_obe_uzy foreign key (uzytkownik_id) references uzytkownik(uzytkownik_id),
	constraint fk_obe_ref foreign key (referat_id) references referat(referat_id)
);



create table propozycja_referat (
	wydarzenie_id	int not null,
	uzytkownik_id	int not null,
	nazwa			varchar(100) not null unique,
	tytul			varchar(100) not null,
	opis			varchar(1000),
	startDate		timestamp,

	constraint fk_prop_uzyt foreign key(uzytkownik_id) references uzytkownik(uzytkownik_id),
	constraint fk_referat_wydarzenie foreign key (wydarzenie_id) references wydarzenie(wydarzenie_id)
);

create role uzytkownik  noinherit;
create role organizator noinherit;


-- organizator
grant SELECT on obecnosc to organizator ;
grant SELECT on ocena to organizator ;
grant SELECT, update, insert on propozycja_referat to organizator ;
grant SELECT, insert, update on referat to organizator;
grant SELECT, update on referat_referat_id_seq to organizator ;
grant SELECT on rejestracje to organizator ;
grant SELECT, insert, update on uzytkownik to organizator ;
grant SELECT, update on uzytkownik_uzytkownik_id_seq to organizator ;
grant SELECT, update, insert on wydarzenie to organizator ;
grant SELECT, update on wydarzenie_wydarzenie_id_seq to organizator ;
grant SELECT on znajomosc to organizator;
grant SELECT on znajomosc_propozycja to organizator;

--uzytkownik
grant insert on obecnosc to uzytkownik;
grant SELECT, insert on ocena to uzytkownik;
grant update, insert, delete on propozycja_referat to uzytkownik ;
grant SELECT on referat to uzytkownik;
grant insert on rejestracje to uzytkownik;
grant select on wydarzenie to uzytkownik;
grant SELECT on znajomosc to uzytkownik;
grant SELECT, insert on znajomosc_propozycja to uzytkownik;
grant connect on database wspomaganie_konferencji to uzytkownik; 

create user administrator with password 'standard8' SUPERUSER;


create or replace function uzytkownik_insdel_fun() 
RETURNS trigger AS $$
	BEGIN
		IF (TG_OP = 'INSERT') THEN
			execute 'create user '||quote_ident(NEW.login)||' with password '||quote_literal(quote_ident(NEW.password));
			execute 'grant uzytkownik to '||quote_ident(new.login);
			return NEW;
		ELSIF (TG_OP = 'DELETE') THEN
			execute 'drop user '||quote_ident(old.login);
			return OLD;
		end if;
	END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER uzytkownik_ins after insert on uzytkownik
	for each row 
	execute procedure uzytkownik_insdel_fun();

CREATE TRIGGER uzytkownik_del before delete on uzytkownik
	for each row 
	execute procedure uzytkownik_insdel_fun();

CREATE TRIGGER znajomosc_prop_ins after insert on znajomosc_propozycja
	for each row 
	execute procedure znajomosc_propozycja_ins();
	
	


create or replace function zapisz_na_wydarzenie(text, text)
returns int AS $$
	DECLARE
		usid numeric;
		evid numeric;
	BEGIN
		select uzytkownik_id into usid from uzytkownik where login=$1;
		select wydarzenie_id into evid from wydarzenie where wydarzenie_nazwa=$2;
		insert into rejestracje values (usid, evid);
		return 0;
	END;
$$ LANGUAGE plpgsql SECURITY DEFINER;



create or replace function utworz_wydarzenie(text, text, text, TIMESTAMP, int, int, text, text)
returns int AS $$
	DECLARE
		ouid  numeric;
		usid  numeric;
		evid  numeric;
		refid numeric;
	BEGIN
		select uzytkownik_id into usid from uzytkownik where login=$1;
		select wydarzenie_id into evid from wydarzenie where wydarzenie_nazwa=$7;
		select uzytkownik_id into ouid from uzytkownik where login=$8;
		
		delete from propozycja_referat where usid=uzytkownik_id and evid=wydarzenie_id and nazwa=$2;
		
		insert into referat(uzytkownik_id, nazwa, tytul, wydarzenie_id, startDate, sala) 
			values (usid, $2, $3, evid, $4, $5);
		
		select referat_id into refid from referat where nazwa=$2;
		
		insert into ocena(uzytkownik_id, referat_id, ocena, typ) values (ouid, refid, $6, 1);
		return 0;
	END;
$$ LANGUAGE plpgsql;



create or replace function potwierdz_obecnosc(text, text)
returns int AS $$
	DECLARE
		usid numeric;
		refid numeric;
	BEGIN
		select uzytkownik_id into usid from uzytkownik where login=$1;
		select wydarzenie_id into refid from referat where nazwa=$2;
		
		insert into obecnosc( uzytkownik_id, referat_id) values (usid, refid);
		
		return 0;
	END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


create or replace function ocen_referat(text, text, int)
returns int AS $$
	DECLARE
		usid numeric;
		refid numeric;
	BEGIN
		select uzytkownik_id into usid from uzytkownik where login=$1;
		select wydarzenie_id into refid from referat where nazwa=$2;
		
		insert into ocena( uzytkownik_id, referat_id, ocena) values (usid, refid, $3);
		
		return 0;
	END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


create or replace function zawrzyj_znajomosc(text, text)
returns int AS $$
	DECLARE
		usid1 numeric;
		usid2 numeric;
	BEGIN
		select uzytkownik_id into usid1 from uzytkownik where login=$1;
		select uzytkownik_id into usid2 from uzytkownik where login=$2;
		
		insert into znajomosc_propozycja values (usid1, usid2);
		
		return 0;
	END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


create or replace function plan(text, int)
returns table( nazwa text, tytul text, czas timestamp, room int) AS 
$$
	DECLARE
		usid numeric;

	BEGIN
		select uzytkownik_id into usid from uzytkownik where login=$1;
		if $2=0 then
			return query
			select referat.nazwa::text, referat.tytul::text, referat.startDate, referat.sala from referat join rejestracje on
			(referat.wydarzenie_id = rejestracje.wydarzenie_id)
			where rejestracje.uzytkownik_id = usid and
			startDate > current_date
			order by startDate;
		else
			return query
			select referat.nazwa::text, referat.tytul::text, referat.startDate, referat.sala from referat join rejestracje on
			(referat.wydarzenie_id = rejestracje.wydarzenie_id)
			where rejestracje.uzytkownik_id = usid and
			startDate > current_date
			order by startDate limit $2;
		end if;
	END;
$$ LANGUAGE plpgsql SECURITY DEFINER;



create or replace function day_plan(text)
returns table( nazwa text, tytul text, czas timestamp, room int) AS 
$$
	BEGIN
		return query 
		select referat.nazwa::text, referat.tytul::text, referat.startDate, referat.sala from referat where startdate >  date( $1 )
		and startdate < date( $1 )  + INTERVAL '1 day' order by startdate;
	END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

create or replace function best_talks(text, text, int, int)
returns table( nnazwa text, ntytul text, nczas timestamp, nroom int) AS 
$$
	BEGIN
		if $4 = 1 then
			if $3 = 0 then
			return query
				select foo.nazwa::text, foo.tytul::text, foo.startDate, foo.sala from (
					select referat_id, referat.nazwa, referat.tytul, referat.startDate, referat.sala, avg(ocena) 
					from referat join ocena using (referat_id)
					group by referat_id order by avg desc
				) as foo where startDate >  date( $1 ) and startDate < date( $2 );
			else
			return query
				select foo.nazwa::text, foo.tytul::text, foo.startDate, foo.sala from (
					select referat_id, referat.nazwa, referat.tytul, referat.startDate, referat.sala, avg(ocena) 
					from referat join ocena using (referat_id)
					group by referat_id order by avg desc
				) as foo where startDate >  date( $1 ) and startDate < date( $2 ) limit $3;
			end if;
			
		else
			if $3=0 then
				return query 
				select foo.nazwa::text, foo.tytul::text, foo.startDate, foo.sala from (
					select referat.referat_id, referat.nazwa, referat.tytul, referat.startDate, referat.sala, avg(ocena) 
					from referat join ocena using (referat_id) join obecnosc on (referat.referat_id = obecnosc.referat_id and ocena.uzytkownik_id = obecnosc.uzytkownik_id)
					group by referat.referat_id order by avg desc
				) as foo where startDate >  date( $1 ) and startDate < date( $2 );
			else
								return query 
				select foo.nazwa::text, foo.tytul::text, foo.startDate, foo.sala from (
					select referat.referat_id, referat.nazwa, referat.tytul, referat.startDate, referat.sala, avg(ocena) 
					from referat join ocena using (referat_id) join obecnosc on (referat.referat_id = obecnosc.referat_id and ocena.uzytkownik_id = obecnosc.uzytkownik_id)
					group by referat.referat_id order by avg desc
				) as foo where startDate >  date( $1 ) and startDate < date( $2 ) limit $3;
			end if;
		end if;
	END;
$$ LANGUAGE plpgsql SECURITY DEFINER;



create or replace function  most_popular_talks(text, text, int)
returns table( nnazwa text, ntytul text, nczas timestamp, nroom int) AS 
$$
	BEGIN
		if $3=0 then
			return query
				select foo.nazwa::text, foo.tytul::text, foo.startDate, foo.sala from (
					select referat_id, referat.nazwa, referat.tytul, referat.startDate, referat.sala, count(obecnosc.uzytkownik_id) 
					from referat join obecnosc using (referat_id)
					group by referat_id order by count desc
			) as foo where startDate >  date( $1 ) and startDate < date( $2 );
		else 
			return query
				select foo.nazwa::text, foo.tytul::text, foo.startDate, foo.sala from (
					select referat_id, referat.nazwa, referat.tytul, referat.startDate, referat.sala, count(obecnosc.uzytkownik_id) 
					from referat join obecnosc using (referat_id)
					group by referat_id order by count desc
			) as foo where startDate >  date( $1 ) and startDate < date( $2 ) limit $3;
		end if;
	END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


create or replace function attended_talks(text)
returns table( nazwa text, tytul text, czas timestamp, room int) AS 
$$
	DECLARE
		usid numeric;

	BEGIN
		select uzytkownik_id into usid from uzytkownik where login=$1;
		
		return query
		select referat.nazwa::text, referat.tytul::text, referat.startDate, referat.sala from obecnosc join referat using (referat_id)
			where obecnosc.uzytkownik_id = usid;
		
	END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


create or replace function abandoned_talks(int)
returns table( nazwa text, tytul text, czas timestamp, room int, num int) AS 
$$
	BEGIN
		if $1=0 then
		return query
			select referat.nazwa::text, referat.tytul::text, referat.startDate, referat.sala, count(rejestracje.uzytkownik_id)::int 
			from referat join
			rejestracje using (wydarzenie_id)
			where (rejestracje.uzytkownik_id, referat_id) 
			not in
			(select uzytkownik_id, referat_id from obecnosc)
			group by referat_id order by count desc;
		else
		return query
			select referat.nazwa::text, referat.tytul::text, referat.startDate, referat.sala, count(rejestracje.uzytkownik_id)::int 
			from referat join
			rejestracje using (wydarzenie_id)
			where (rejestracje.uzytkownik_id, referat_id) 
			not in
			(select uzytkownik_id, referat_id from obecnosc)
			group by referat_id order by count desc limit $1;
		end if;
		
	END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
