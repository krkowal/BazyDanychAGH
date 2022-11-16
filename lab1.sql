-- tabela słownikowa
CREATE TABLE COUNTRY
(
    COUNTRY VARCHAR2(50)
);

-- inserty przykładowaymi danymi

-- Person - 10 osób
INSERT INTO person (firstname, lastname) VALUES('Adam', 'Kowalski');
INSERT INTO person (firstname, lastname) VALUES('Jan', 'Nowak');
INSERT INTO PERSON (FIRSTNAME, LASTNAME) VALUES ('Kasia','Admin');
INSERT INTO PERSON (FIRSTNAME, LASTNAME) values ('Iza','Kowalczyk');
INSERT INTO PERSON (FIRSTNAME, LASTNAME) values ('Inez','Przeniosło');
INSERT INTO PERSON (FIRSTNAME, LASTNAME) values ('Piotr','Ptak');
INSERT INTO PERSON (FIRSTNAME, LASTNAME) values ('Krzysztof','Kowalik');
INSERT INTO PERSON (FIRSTNAME, LASTNAME) values ('Oskar','Jószczyk');
INSERT INTO PERSON (FIRSTNAME, LASTNAME) values ('Anna','Urwał');
INSERT INTO PERSON (FIRSTNAME, LASTNAME) values ('Kunegunda','Grunwald');

-- Trip - 4 wycieczki
INSERT INTO TRIP (NAME, COUNTRY, TRIP_DATE, NO_PLACES) VALUES ('Wycieczka do Oslo', 'Norwegia',to_date('2020-07-06','YYYY-MM-DD'),5);
INSERT INTO TRIP (NAME, COUNTRY, TRIP_DATE, NO_PLACES) VALUES ('Wycieczka do Berlina', 'Niemcy',to_date('2023-03-29','YYYY-MM-DD'),3);
INSERT INTO trip (name, country, trip_date, no_places) VALUES ('Wycieczka do Paryza','Francja',TO_DATE('2021-09-03','YYYY-MM-DD'),3);
INSERT INTO trip (name, country, trip_date, no_places) VALUES ('Wycieczka do Krakowa','Polska',TO_DATE('2021-12-05','YYYY-MM-DD'),3);

-- Reservation - 10 rezerwacji
INSERT INTO reservation(trip_id, person_id, status) VALUES (4,1,'N');
INSERT INTO reservation(trip_id, person_id, status) VALUES (2,2,'P');
INSERT INTO reservation(trip_id, person_id, status) VALUES (3,3,'C');
INSERT INTO reservation(trip_id, person_id, status) VALUES (4,4,'C');
INSERT INTO reservation(trip_id, person_id, status) VALUES (1,5,'P');
INSERT INTO reservation(trip_id, person_id, status) VALUES (1,6,'C');
INSERT INTO reservation(trip_id, person_id, status) VALUES (1,7,'P');
INSERT INTO reservation(trip_id, person_id, status) VALUES (1,8,'N');
INSERT INTO reservation(trip_id, person_id, status) VALUES (3,9,'N');
INSERT INTO reservation(trip_id, person_id, status) VALUES (2,10,'C');

-- Widoki

-- CREATE OR REPLACE PROCEDURE createViews
-- AS
-- BEGIN
--     EXECUTE IMMEDIATE 'CREATE OR REPLACE VIEW V_Reservations AS select * from RESERVATION';
--     EXECUTE IMMEDIATE 'CREATE OR REPLACE VIEW V_Trips AS select * from TRIP';
--     EXECUTE IMMEDIATE 'CREATE OR REPLACE VIEW V_ AS select * from RESERVATION';
-- end;

CREATE OR REPLACE FUNCTION get_available_places (trip IN NUMBER)
    RETURN NUMBER
IS
    trip_count number;
    no_places number;
BEGIN
    SELECT count(*) into trip_count from RESERVATION R
    where R.STATUS in ('N','P') and R.TRIP_ID = trip;
    SELECT T.no_places into no_places from TRIP T
    where T.TRIP_ID = trip;
    return no_places-trip_count;
end;


CREATE OR REPLACE VIEW V_Reservations as
    select T.COUNTRY, T.TRIP_DATE, T.NAME, P.FIRSTNAME, P.LASTNAME, RESERVATION_ID, STATUS from RESERVATION
    join PERSON P on P.PERSON_ID = RESERVATION.PERSON_ID
    join TRIP T on T.TRIP_ID = RESERVATION.TRIP_ID;

CREATE OR REPLACE VIEW V_Trips as
    select Distinct T.COUNTRY, T.TRIP_DATE, T.NAME, T.NO_PLACES, get_available_places(T.TRIP_ID) as available_places
    from TRIP T;

CREATE OR REPLACE VIEW V_AvailableTrips as
    select T.COUNTRY, T.TRIP_DATE, T.NAME, T.NO_PLACES, available_places from V_TRIPS T
    where T.AVAILABLE_PLACES > 0;

create or replace type reservation_type FORCE as object
    (
        COUNTRY varchar2(50),
        TRIP_DATE DATE,
        NAME varchar2(100),
        FIRSTNAME varchar2(50),
        LASTNAME varchar2(50),
        RESERVATION_ID number,
        STATUS char
    );
CREATE TYPE Trip_Participants_type1 as table of reservation_type;

CREATE OR REPLACE FUNCTION TripParticipants (tripID IN NUMBER)
    return Trip_Participants_type1
IS
    tab Trip_Participants_type1;
    trips number;
BEGIN
    select count(*) into trips from TRIP where TRIP_ID=tripID;

    if  trips=0 then
        raise_application_error(-20101,'trip_id does not exist!');
    end if;
    SELECT  reservation_type(COUNTRY, TRIP_DATE, NAME, FIRSTNAME, LASTNAME, R.RESERVATION_ID, R.STATUS) BULK COLLECT
    into tab from V_RESERVATIONS R
        join RESERVATION R2 on R.RESERVATION_ID = R2.RESERVATION_ID
        where R2.TRIP_ID=tripID;
    return tab;
end;

create or replace function PersonReservations(personID in NUMBER)
return Trip_Participants_type1
as
    persons number;
    tab Trip_Participants_type1;
BEGIN
    select count(*) into persons from PERSON where PERSON_ID = personID;
    if persons = 0 then
        raise_application_error(-20102,'person_id does not exist!');
    end if;
    SELECT  reservation_type(COUNTRY, TRIP_DATE, NAME, P.FIRSTNAME, P.LASTNAME, R.RESERVATION_ID, R.STATUS) BULK COLLECT
    into tab from V_RESERVATIONS R
        join RESERVATION R2 on R.RESERVATION_ID = R2.RESERVATION_ID
        join PERSON P on P.PERSON_ID = R2.PERSON_ID
        where P.PERSON_ID = personID;
    return tab;
END;

create or replace type available_trips as object
(
    COUNTRY varchar2(50),
    TRIP_DATE DATE
);
create or replace type available_trips_type as TABLE OF available_trips;

Create or replace function AvailableTrips(countryName IN varchar2, date_from IN Date, date_to IN DATE)
return available_trips_type
as
    tab available_trips_type;
BEGIN
    select available_trips(T.COUNTRY, T.TRIP_DATE) bulk collect into tab from TRIP T
    where T.COUNTRY = countryName and t.TRIP_DATE BETWEEN date_from and date_to;
    return tab;
end;