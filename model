create database wspomaganie_konferencji;
\c wspomaganie_konferencji

drop table if exists wydarzenie cascade;
create table wydarzenie (
	wydarzenie_id 	serial primary key,
	startDate 		TIMESTAMP not null default clock_timestamp(),
	endDate 		TIMESTAMP not null default clock_timestamp()
);


drop table if exists table uzytkownik cascade;
create table uzytkownik (
	uzytkownik_id 	serial primary key,
	imie 			varchar(50),
	nazwisko 		varchar(50),
	login			varchar(50) not null unique,
	password		varchar(50) not null
);



drop table if exists referat cascade;
create table referat (
	referat_id 		serial primary key,
	uzytkownik_id	int not null,
	wydarzenie_id	int not null,
	startDate 		TIMESTAMP not null default clock_timestamp(),
	endDate			TIMESTAMP not null default clock_timestamp(),
	sala			int not null,

	constraint fk_referat_wydarzenie foreign key (wydarzenie_id) references wydarzenie(wydarzenie_id),
	constraint fk_referat_uzytkownik foreign key (uzytkownik_id) references uzytkownik(uzytkownik_id)
);


drop table if exists ocena cascade;
create table ocena (
	uzytkownik_id	int not null,
	referat_id		int not null,
	ocena			int not null check ( ocena >= 0 and ocena <=10),
	
	constraint fk_ocena_referat foreign key (referat_id) references referat(referat_id),
	constraint fk_ocena_uzytkownik foreign key (uzytkownik_id) references uzytkownik(uzytkownik_id)
);



drop table if exists znajomosc cascade;
create table znajomosc (
	kto1_id			int not null,
	kto2_id			int not null,

	constraint fk_kto foreign key (kto1_id) references uzytkownik(uzytkownik_id),
	constraint fk_kogo foreign key (kto2_id) references uzytkownik(uzytkownik_id)
);


drop table if exists rejestracje cascade;
create table rejestracje (
	uzytkownik_id	int not null,
	wydarzenie_id	int not null,

	constraint fk_rej_wyd foreign key (wydarzenie_id) references wydarzenie(wydarzenie_id),
	constraint fk_rej_uzy foreign key (uzytkownik_id) references uzytkownik(uzytkownik_id)
);



--funkcja do sprawdzania poprawnosci w tabeli obecnosc (sprawdza czy osoba jest zapisana na wydarzenie którego dotyczy referat
create or replace function zapisanyNaWydarzenie(int, int)
	returns bool as
$$
	select exists ( select * from uzytkownik join rejestracje using (uzytkownik_id)
							join referat using (wydarzenie_id)
					where (uzytkownik.uzytkownik_id=$2 and referat_id=$1)
	);
$$
language sql stable;


drop table if exists obecnosc cascade;
create table obecnosc (
	uzytkownik_id	int not null,
	referat_id		int not null check ( zapisanyNaWydarzenie(referat_id, uzytkownik_id) ),

	constraint fk_obe_uzy foreign key (uzytkownik_id) references uzytkownik(uzytkownik_id),
	constraint fk_obe_ref foreign key (referat_id) references referat(referat_id)
);


drop table if exists propozycja_referat cascade;
create table propozycja_referat (
	uzytkownik_id	int not null,
	nazwa			varchar(100),
	opis			varchar(1000),

	constraint fk_prop_uzyt foreign key(uzytkownik_id) references uzytkownik(uzytkownik_id)	
);

create role uzytkownik  noinherit;
create role organizator noinherit;


-- organizator
grant SELECT on obecnosc to organizator ;
grant SELECT on ocena to organizator ;
grant SELECT, update, insert on propozycja_referat to organizator ;
grant SELECT, insert, update on referat to organizator;
grant SELECT on rejestracje to organizator ;
grant SELECT on uzytkownik to organizator ;
grant SELECT, update, insert on wydarzenie to organizator ;
grant SELECT on znajomosc to organizator;

--uzytkownik
grant insert on obecnosc to uzytkownik;
grant SELECT, insert on ocena to uzytkownik;
grant SELECT, update, insert on propozycja_referat to uzytkownik ;
grant SELECT on referat to uzytkownik;
grant insert on rejestracje to uzytkownik;
grant select on wydarzenie to uzytkownik;
grant SELECT,insert on znajomosc to uzytkownik;

create user administrator with password 'standard8';
grant organizator to administrator ;

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
$$ LANGUAGE plpgsql;

CREATE TRIGGER uzytkownik_ins after insert on uzytkownik
	for each row 
	execute procedure uzytkownik_insdel_fun();

CREATE TRIGGER uzytkownik_del before delete on uzytkownik
	for each row 
	execute procedure uzytkownik_insdel_fun();
