CREATE TABLE PERSON
(
    PERSON_ID INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    FIRSTNAME VARCHAR(50),
    LASTNAME  VARCHAR(50),
    CONSTRAINT PERSON_PK PRIMARY KEY
        (
         PERSON_ID
            )
);


CREATE TABLE TRIP
(
    TRIP_ID   INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    NAME      VARCHAR(100),
    COUNTRY_ID   INT,
    TRIP_DATE DATE,
    NO_PLACES INT,
    CONSTRAINT TRIP_PK PRIMARY KEY
        (
         TRIP_ID
            )
);



CREATE TABLE RESERVATION
(
    RESERVATION_ID INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    TRIP_ID        INT,
    PERSON_ID      INT,
    STATUS         CHAR(1),
    CONSTRAINT RESERVATION_PK PRIMARY KEY
        (
         RESERVATION_ID
            )
);

CREATE TABLE COUNTRY
(
    COUNTRY_ID INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    COUNTRY    VARCHAR(50),
    CONSTRAINT COUNTRY_PK PRIMARY KEY
        (
         COUNTRY_ID
            )
);

ALTER TABLE RESERVATION
    ADD CONSTRAINT RESERVATION_FK1 FOREIGN KEY
        (
         PERSON_ID
            )
        REFERENCES PERSON
            (
             PERSON_ID
                )
            ;

ALTER TABLE RESERVATION
    ADD CONSTRAINT RESERVATION_FK2 FOREIGN KEY
        (
         TRIP_ID
            )
        REFERENCES TRIP
            (
             TRIP_ID
                )
            ;

ALTER TABLE RESERVATION
    ADD CONSTRAINT RESERVATION_CHK1 CHECK
        (status IN ('N', 'P', 'C'))
        ;



ALTER TABLE TRIP
    ADD CONSTRAINT TRIP_FK1 FOREIGN KEY
        (
         COUNTRY_ID
            )
        REFERENCES COUNTRY (COUNTRY_ID)
            ;

INSERT INTO PERSON (firstname, lastname)
VALUES ('Adam', 'Kowalski');
INSERT INTO PERSON (firstname, lastname)
VALUES ('Jan', 'Nowak');
INSERT INTO PERSON (FIRSTNAME, LASTNAME)
VALUES ('Kasia', 'Admin');
INSERT INTO PERSON (FIRSTNAME, LASTNAME)
VALUES ('Iza', 'Kowalczyk');
INSERT INTO PERSON (FIRSTNAME, LASTNAME)
VALUES ('Inez', 'Przeniosło');
INSERT INTO PERSON (FIRSTNAME, LASTNAME)
VALUES ('Piotr', 'Ptak');
INSERT INTO PERSON (FIRSTNAME, LASTNAME)
VALUES ('Krzysztof', 'Kowalik');
INSERT INTO PERSON (FIRSTNAME, LASTNAME)
VALUES ('Oskar', 'Jószczyk');
INSERT INTO PERSON (FIRSTNAME, LASTNAME)
VALUES ('Anna', 'Urwał');
INSERT INTO PERSON (FIRSTNAME, LASTNAME)
VALUES ('Kunegunda', 'Grunwald');

-- Country - 4 kraje
INSERT INTO COUNTRY (COUNTRY)
VALUES ('Norwegia');
INSERT INTO COUNTRY (COUNTRY)
VALUES ('Niemcy');
INSERT INTO COUNTRY (COUNTRY)
VALUES ('Francja');
INSERT INTO COUNTRY (COUNTRY)
VALUES ('Polska');

-- Trip - 4 wycieczki
INSERT INTO TRIP (NAME, COUNTRY_ID, TRIP_DATE, NO_PLACES)
VALUES ('Wycieczka do Oslo', 1, TO_DATE('2020-07-06', 'YYYY-MM-DD'), 5);
INSERT INTO TRIP (NAME, COUNTRY_ID, TRIP_DATE, NO_PLACES)
VALUES ('Wycieczka do Berlina', 2, TO_DATE('2023-03-29', 'YYYY-MM-DD'), 3);
INSERT INTO TRIP (name, COUNTRY_ID, TRIP_DATE, NO_PLACES)
VALUES ('Wycieczka do Paryza', 3, TO_DATE('2021-09-03', 'YYYY-MM-DD'), 3);
INSERT INTO TRIP (name, COUNTRY_ID, TRIP_DATE, NO_PLACES)
VALUES ('Wycieczka do Krakowa', 4, TO_DATE('2021-12-05', 'YYYY-MM-DD'), 3);

-- Reservation - 10 rezerwacji
INSERT INTO RESERVATION(trip_id, person_id, status)
VALUES (4, 1, 'N');
INSERT INTO RESERVATION(trip_id, person_id, status)
VALUES (2, 2, 'P');
INSERT INTO RESERVATION(trip_id, person_id, status)
VALUES (3, 3, 'C');
INSERT INTO RESERVATION(trip_id, person_id, status)
VALUES (4, 4, 'C');
INSERT INTO RESERVATION(trip_id, person_id, status)
VALUES (1, 5, 'P');
INSERT INTO RESERVATION(trip_id, person_id, status)
VALUES (1, 6, 'C');
INSERT INTO RESERVATION(trip_id, person_id, status)
VALUES (1, 7, 'P');
INSERT INTO RESERVATION(trip_id, person_id, status)
VALUES (1, 8, 'N');
INSERT INTO RESERVATION(trip_id, person_id, status)
VALUES (3, 9, 'N');
INSERT INTO RESERVATION(trip_id, person_id, status)
VALUES (2, 10, 'C');


CREATE OR REPLACE FUNCTION GetAvailablePlaces(tripId integer)
    RETURNS int
language plpgsql
as
$$
    DECLARE
    trip_count integer;
    no_places  integer;
    trip_exists integer;
BEGIN
    SELECT COUNT(*)
    INTO trip_exists
    FROM TRIP
    WHERE TRIP_ID=tripId;

    IF trip_exists=0 THEN
        RAISE EXCEPTION 'trip_id does not exist!';
    END IF;

    SELECT T.no_places
    INTO no_places
    FROM TRIP T
    WHERE T.TRIP_ID = tripId;

    SELECT COUNT(*)
    INTO trip_count
    FROM RESERVATION R
    WHERE R.STATUS IN ('N', 'P')
      AND R.TRIP_ID = tripId;

    RETURN no_places - trip_count;
END;
$$;

select * from GetAvailablePlaces(2);

CREATE OR REPLACE VIEW V_Reservations AS
SELECT C2.COUNTRY,
       T.TRIP_DATE,
       T.NAME,
       P.FIRSTNAME,
       P.LASTNAME,
       RESERVATION_ID,
       STATUS
FROM RESERVATION
         JOIN PERSON P ON
    P.PERSON_ID = RESERVATION.PERSON_ID
         JOIN TRIP T ON
    T.TRIP_ID = RESERVATION.TRIP_ID
         JOIN COUNTRY C2 ON
    T.COUNTRY_ID = C2.COUNTRY_ID;


CREATE OR REPLACE VIEW V_Trips AS
SELECT DISTINCT C2.COUNTRY,
                T.TRIP_DATE,
                T.NAME,
                T.NO_PLACES,
                GetAvailablePlaces(T.TRIP_ID)
                    AS available_places
FROM TRIP T
JOIN COUNTRY C2 ON
    T.COUNTRY_ID = C2.COUNTRY_ID;

CREATE OR REPLACE VIEW V_AvailableTrips AS
SELECT T.COUNTRY,
       T.TRIP_DATE,
       T.NAME,
       T.NO_PLACES,
       available_places
FROM V_TRIPS T
WHERE T.AVAILABLE_PLACES > 0;


CREATE TYPE reservation_type AS
(
    COUNTRY        VARCHAR(50),
    TRIP_DATE      DATE,
    NAME           VARCHAR(100),
    FIRSTNAME      VARCHAR(50),
    LASTNAME       VARCHAR(50),
    RESERVATION_ID INT,
    STATUS         CHAR
);

CREATE OR REPLACE FUNCTION TripParticipants(tripID INT)
    RETURNS SETOF reservation_type
LANGUAGE plpgsql
AS

$$
DECLARE
    trips integer;
BEGIN
    SELECT COUNT(*)
    INTO trips
    FROM TRIP
    WHERE TRIP_ID = tripID;

    IF trips=0 THEN
        RAISE EXCEPTION 'trip_id does not exist!';
    END IF;

    return QUERY (SELECT
        C.COUNTRY,
        TRIP_DATE,
        NAME,
        FIRSTNAME,
        LASTNAME,
        R.RESERVATION_ID,
        R.STATUS
    FROM V_RESERVATIONS R
    JOIN RESERVATION R2 ON
        R.RESERVATION_ID = R2.RESERVATION_ID
    JOIN COUNTRY C ON
        R.COUNTRY = C.COUNTRY
    WHERE R2.TRIP_ID = tripID
        AND
        R.STATUS <> 'C');
END;
$$;

select * from TripParticipants(1);

CREATE OR REPLACE FUNCTION PersonReservations(personID  INT)
    RETURNS SETOF reservation_type
language plpgsql
AS
    $$
    DECLARE
    persons integer;
BEGIN
    SELECT COUNT(*)
    INTO persons
    FROM PERSON
    WHERE PERSON_ID = personID;

    IF persons = 0 THEN
        RAISE EXCEPTION 'person_id does not exist!';
    END IF;

    RETURN QUERY (SELECT
        COUNTRY,
        TRIP_DATE,
        NAME,
        P.FIRSTNAME,
        P.LASTNAME,
        R.RESERVATION_ID,
        R.STATUS

    FROM V_RESERVATIONS R
             JOIN RESERVATION R2 ON
                 R.RESERVATION_ID = R2.RESERVATION_ID
             JOIN PERSON P ON
                 P.PERSON_ID = R2.PERSON_ID
    WHERE P.PERSON_ID = personID);
END;
$$;
SELECT * FROM PersonReservations(1);


CREATE TYPE available_trips  AS
(
    COUNTRY   VARCHAR(50),
    TRIP_DATE DATE,
    NAME           VARCHAR(100),
    NO_PLACES           integer,
    AVAILABLE_PLACES integer
);

CREATE OR REPLACE FUNCTION AvailableTrips(countryName IN VARCHAR, date_from IN Date, date_to IN DATE)
    RETURNS SETOF available_trips
language plpgsql
AS
$$
BEGIN
    RETURN QUERY (SELECT
        T.COUNTRY,
        T.TRIP_DATE,
        T.NAME,
        T.NO_PLACES,
        T.AVAILABLE_PLACES
        FROM V_AVAILABLETRIPS T
        WHERE T.COUNTRY = countryName
        AND T.TRIP_DATE BETWEEN date_from AND date_to);
END;
$$;

SELECT *
FROM AvailableTrips('Norwegia', TO_DATE('2020-01-01','yyyy-mm-dd'),TO_DATE('2022-01-01','yyyy-mm-dd'));

CREATE OR REPLACE PROCEDURE AddReservation(tripID IN INT, personID IN INT)
language plpgsql
AS
$$
DECLARE
    person_exists INTEGER;
    available_places INTEGER := GetAvailablePlaces(tripID);
    trip_date DATE;
BEGIN
    SELECT COUNT(*)
    INTO person_exists
    FROM PERSON
    WHERE PERSON_ID = personID;

    SELECT TRIP.TRIP_DATE
    INTO trip_date
    FROM TRIP
    WHERE TRIP_ID=tripID;

    IF person_exists = 0 THEN
        RAISE 'person_id does not exist!';
    END IF;

    IF available_places = 0 THEN
        RAISE 'Cannot add new reservation because there are no places left';
    END IF;

    IF trip_date <= CURRENT_DATE THEN
        RAISE 'Cannot add new reservation because the trip has already begun / ended';
    END IF;
    INSERT
    INTO RESERVATION
        (TRIP_ID, PERSON_ID, STATUS)
    VALUES (tripID, personID, 'N');
    COMMIT;
END;
$$;

CALL  AddReservation(1,7);

SELECT *
FROM PersonReservations(7);

CREATE OR REPLACE PROCEDURE ModifyReservationStatus(reservationID IN INT, status_char IN CHAR)
language plpgsql
AS
$$
    DECLARE
    tripid INTEGER;
    prev_status CHAR(1);
    available_places INTEGER;
    reservation_exists INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO reservation_exists
    FROM RESERVATION
    WHERE RESERVATION_ID = reservationID;

    IF reservation_exists=0 THEN
        RAISE 'reservation_id does not exist!';
    END IF;

    SELECT TRIP_ID,
           STATUS
    INTO tripid,
        prev_status
    FROM RESERVATION
    WHERE RESERVATION_ID = reservationID;

    available_places := GetAvailablePlaces(tripid);

    IF prev_status = 'C' AND available_places = 0 THEN
        RAISE 'Status of reservation is "canceled" and available places equals 0';
    END IF;
    CALL AddReservationLog(reservationID, CURRENT_DATE, status_char);

    UPDATE RESERVATION
    SET STATUS = status_char
    WHERE RESERVATION_ID = reservationID;
    COMMIT;
END
$$;


CALL ModifyReservationStatus(11, 'P');

SELECT *
FROM PersonReservations(7);

CREATE OR REPLACE PROCEDURE ModifyNoPlaces(tripID IN INTEGER, places IN INTEGER)
language plpgsql
AS
$$
DECLARE
    reserved_places INTEGER;
BEGIN
    SELECT (NO_PLACES - GetAvailablePlaces(TRIP_ID))
    INTO reserved_places
    FROM TRIP
    WHERE TRIP_ID = tripID;

    IF reserved_places > places THEN
        RAISE EXCEPTION 'The Number of reserved places is bigger than entered places number';
    END IF;

    UPDATE TRIP
    SET NO_PLACES = places
    WHERE TRIP_ID = tripID;
    COMMIT;
END;
$$;


CALL ModifyNoPlaces(1, 7);
CALL ModifyNoPlaces(2, 6);

SELECT *
FROM V_Trips;


CALL ModifyNoPlaces(1,1);

CREATE TABLE RESERVATION_LOG
(
    LOG_ID         INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    RESERVATION_ID INTEGER,
    CHANGE_DATE    DATE,
    STATUS         CHAR(1),
    CONSTRAINT LOG_PK PRIMARY KEY (LOG_ID)
);

ALTER TABLE RESERVATION_LOG
    ADD CONSTRAINT RESERVATION_LOG_FK1 FOREIGN KEY
        (RESERVATION_ID)
        REFERENCES RESERVATION
            (RESERVATION_ID);

ALTER TABLE RESERVATION_LOG
    ADD CONSTRAINT RESERVATION_LOG_CHK1 CHECK
        (STATUS IN ('P', 'N', 'C'));

CREATE OR REPLACE PROCEDURE AddReservationLog(reservationID IN INTEGER, insertDate IN DATE,
status_change IN CHAR)
LANGUAGE plpgsql
AS
$$
BEGIN
    INSERT
    INTO RESERVATION_LOG (RESERVATION_ID,
                          CHANGE_DATE,
                          STATUS)
    VALUES (reservationID,
            insertDate,
            status_change);
END;
$$;


CALL AddReservationLog(7, CURRENT_DATE, 'C');

SELECT *
FROM RESERVATION_LOG;

ALTER TABLE TRIP
  ADD NO_AVAILABLE_PLACES INTEGER;

CREATE OR REPLACE PROCEDURE Przelicz()
LANGUAGE plpgsql
AS
$$
DECLARE
    available_places INTEGER;
    t TRIP%rowtype;
BEGIN
    FOR t IN SELECT *
              FROM TRIP
        LOOP
            SELECT GetAvailablePlaces(TRIP_ID)
            INTO available_places
            FROM TRIP
            WHERE TRIP_ID = t.TRIP_ID;

            UPDATE TRIP
            SET NO_AVAILABLE_PLACES = available_places
            WHERE TRIP_ID = t.TRIP_ID;
        END LOOP;
END;
$$;

CALL Przelicz();

SELECT *
FROM TRIP;

CREATE OR REPLACE VIEW V_Trips2 AS
SELECT DISTINCT C2.COUNTRY,
                T.TRIP_DATE,
                T.NAME,
                T.NO_PLACES,
                T.NO_AVAILABLE_PLACES
                    AS available_places
FROM TRIP T
JOIN COUNTRY C2 ON
    T.COUNTRY_ID = C2.COUNTRY_ID;

CREATE OR REPLACE PROCEDURE AddReservation2(tripID IN INT, personID IN INT)
LANGUAGE plpgsql
AS
$$
DECLARE
    person_exists INTEGER;
    available_places INTEGER;
    trip_date DATE;
    trip_exists INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO trip_exists
    FROM TRIP
    WHERE TRIP_ID=tripId;

    IF trip_exists=0 THEN
        RAISE 'trip_id does not exist!';
    END IF;

    SELECT T.NO_AVAILABLE_PLACES
    INTO available_places
    FROM TRIP T
    WHERE TRIP_ID = tripID;


    SELECT COUNT(*)
    INTO person_exists
    FROM PERSON
    WHERE PERSON_ID = personID;

    SELECT TRIP.TRIP_DATE
    INTO trip_date
    FROM TRIP
    WHERE TRIP_ID=tripID;

    IF person_exists = 0 THEN
        RAISE 'person_id does not exist!';
    END IF;

    IF available_places = 0 THEN
        RAISE 'Cannot add new reservation because there are no places left';
    END IF;

    IF trip_date <= CURRENT_DATE THEN
        RAISE 'Cannot add new reservation because the trip has already begun / ended';
    END IF;
    INSERT
    INTO RESERVATION
        (TRIP_ID, PERSON_ID, STATUS)
    VALUES (tripID, personID, 'N');
    UPDATE TRIP
    SET
    NO_AVAILABLE_PLACES = (TRIP.NO_AVAILABLE_PLACES - 1)
    WHERE TRIP.TRIP_ID = TRIPID;
    COMMIT;
END
$$;

CREATE OR REPLACE PROCEDURE ModifyReservationStatus2(reservationID IN INTEGER, status_char IN CHAR)
LANGUAGE plpgsql
AS
$$
DECLARE
    tripid INTEGER;
    prev_status CHAR(1);
    available_places INTEGER;
    reservation_exists INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO reservation_exists
    FROM RESERVATION
    WHERE RESERVATION_ID = reservationID;

    IF reservation_exists=0 THEN
        RAISE 'reservation_id does not exist!';
    END IF;

    SELECT TRIP_ID,
           STATUS
    INTO tripid,
        prev_status
    FROM RESERVATION
    WHERE RESERVATION_ID = reservationID;

    SELECT TRIP.NO_AVAILABLE_PLACES
    INTO available_places
    FROM TRIP;

    IF prev_status = 'C' AND available_places = 0 THEN
        RAISE 'Status of reservation is "canceled" and available places equals 0';
    END IF;

    UPDATE RESERVATION
    SET STATUS = status_char
    WHERE RESERVATION_ID = reservationID;

    IF status_char = 'C' AND prev_status <> 'C' THEN
        UPDATE TRIP
        SET
        NO_AVAILABLE_PLACES = (TRIP.NO_AVAILABLE_PLACES + 1)
        WHERE TRIP.TRIP_ID = TRIPID;
    ELSIF  status_char <> 'C' AND prev_status = 'C' THEN
        UPDATE TRIP
        SET
        NO_AVAILABLE_PLACES = (TRIP.NO_AVAILABLE_PLACES - 1)
        WHERE TRIP.TRIP_ID = TRIPID;
    end if;

    CALL AddReservationLog(reservationID,CURRENT_DATE,status_char);
    COMMIT;
END
$$;

CREATE OR REPLACE PROCEDURE ModifyNoPlaces2(tripID IN INTEGER, places IN INTEGER)
LANGUAGE plpgsql
AS
$$
DECLARE
    reserved_places INTEGER;
    trip_exists INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO trip_exists
    FROM TRIP
    WHERE TRIP_ID=tripId;

    IF trip_exists=0 THEN
        RAISE 'trip_id does not exist!';
    END IF;

    SELECT (NO_PLACES - NO_AVAILABLE_PLACES)
    INTO reserved_places
    FROM TRIP
    WHERE TRIP_ID = tripID;

    IF reserved_places > places THEN
        RAISE 'The Number of reserved places is bigger than entered places number';
    END IF;

    UPDATE TRIP
    SET NO_PLACES = places
    WHERE TRIP_ID = tripID;

    UPDATE TRIP
    SET
      NO_AVAILABLE_PLACES = ((PLACES - TRIP.NO_PLACES) + TRIP.NO_AVAILABLE_PLACES)
    WHERE TRIP.TRIP_ID = TRIPID;
    COMMIT;
END;
$$;


CREATE OR REPLACE FUNCTION ReservationLogTrigger() RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    CALL AddReservationLog(new.RESERVATION_ID, current_date, new.STATUS);
    RETURN NEW;
END
$$;

CREATE OR REPLACE TRIGGER RESERVATION_LOG_TRIGGER
    AFTER INSERT OR UPDATE
    ON RESERVATION
    FOR EACH ROW
EXECUTE PROCEDURE ReservationLogTrigger();

CREATE OR REPLACE FUNCTION ReservationDeletionTrigger() RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    RAISE  'Reservations cannot be deleted';
END
$$;

CREATE OR REPLACE TRIGGER RESERVATION_DELETE_TRIGGER
    BEFORE DELETE
    ON RESERVATION
    FOR EACH ROW
EXECUTE PROCEDURE ReservationDeletionTrigger();

CREATE OR REPLACE PROCEDURE ModifyReservationStatus3(reservationID IN INTEGER, status_char IN CHAR)
LANGUAGE plpgsql
AS
$$
DECLARE
    tripid INTEGER;
    prev_status CHAR(1);
    available_places INTEGER;
    reservation_exists INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO reservation_exists
    FROM RESERVATION
    WHERE RESERVATION_ID = reservationID;

    IF reservation_exists=0 THEN
        RAISE 'reservation_id does not exist!';
    END IF;

    SELECT TRIP_ID,
           STATUS
    INTO tripid,
        prev_status
    FROM RESERVATION
    WHERE RESERVATION_ID = reservationID;

    SELECT TRIP.NO_AVAILABLE_PLACES
    INTO available_places
    FROM TRIP;

    IF prev_status = 'C' AND available_places = 0 THEN
        RAISE 'Status of reservation is "canceled" and available places equals 0';
    END IF;

    UPDATE RESERVATION
    SET STATUS = status_char
    WHERE RESERVATION_ID = reservationID;

    IF status_char = 'C' AND prev_status <> 'C' THEN
        UPDATE TRIP
        SET NO_AVAILABLE_PLACES = TRIP.NO_AVAILABLE_PLACES + 1
        WHERE TRIP.TRIP_ID = tripid;
    ELSIF  status_char <> 'C' AND prev_status = 'C' THEN
        UPDATE TRIP
        SET NO_AVAILABLE_PLACES = TRIP.NO_AVAILABLE_PLACES - 1
        WHERE TRIP.TRIP_ID = TRIPID;
    end if;
    COMMIT;
END;
$$;

CREATE OR REPLACE FUNCTION ReservationUpdateTrigger() RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
DECLARE
    update_count INT := 0;
BEGIN
    IF (new.STATUS = 'C') THEN
        IF (old.STATUS <> 'C') THEN
            update_count := 1;
        END IF;
    ELSE
        IF (old.STATUS = 'C') THEN
            update_count := -1;
        END IF;
    END IF;

    UPDATE TRIP table_trip
    SET NO_AVAILABLE_PLACES = table_trip.NO_AVAILABLE_PLACES + update_count
    WHERE table_trip.TRIP_ID = new.TRIP_ID;
END
$$;

CREATE OR REPLACE TRIGGER RESERVATION_UPDATE_TRIGGER
    AFTER INSERT OR UPDATE
    ON RESERVATION
    FOR EACH ROW
EXECUTE PROCEDURE ReservationUpdateTrigger();

CREATE OR REPLACE FUNCTION TripUpdateTrigger() RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF (old.NO_PLACES <> new.NO_PLACES) THEN
        new.NO_AVAILABLE_PLACES := new.NO_AVAILABLE_PLACES + (new.NO_PLACES - old.NO_PLACES);
        RETURN NEW;
    END IF;
END
$$;

CREATE OR REPLACE TRIGGER TRIP_UPDATE_TRIGGER
    BEFORE UPDATE
    ON TRIP
    FOR EACH ROW
EXECUTE PROCEDURE TripUpdateTrigger();

CREATE OR REPLACE PROCEDURE AddReservation4(tripID IN INT, personID IN INT)
LANGUAGE plpgsql
AS
$$
DECLARE
    person_exists INTEGER;
    available_places INTEGER;
    trip_date DATE;
    trip_exists INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO trip_exists
    FROM TRIP
    WHERE TRIP_ID=tripId;

    IF trip_exists=0 THEN
        RAISE 'trip_id does not exist!';
    END IF;

    SELECT T.NO_AVAILABLE_PLACES
    INTO available_places
    FROM TRIP T
    WHERE TRIP_ID = tripID;


    SELECT COUNT(*)
    INTO person_exists
    FROM PERSON
    WHERE PERSON_ID = personID;

    SELECT TRIP.TRIP_DATE
    INTO trip_date
    FROM TRIP
    WHERE TRIP_ID=tripID;

    IF person_exists = 0 THEN
        RAISE 'person_id does not exist!';
    END IF;

    IF available_places = 0 THEN
        RAISE 'Cannot add new reservation because there are no places left';
    END IF;

    IF trip_date <= CURRENT_DATE THEN
        RAISE 'Cannot add new reservation because the trip has already begun / ended';
    END IF;
    INSERT
    INTO RESERVATION
        (TRIP_ID, PERSON_ID, STATUS)
    VALUES (tripID, personID, 'N');
    COMMIT;
END
$$;

CREATE OR REPLACE PROCEDURE ModifyReservationStatus4(reservationID IN INTEGER, status_char IN CHAR)
LANGUAGE plpgsql
AS
$$
DECLARE
    tripid INTEGER;
    prev_status CHAR(1);
    available_places INTEGER;
    reservation_exists INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO reservation_exists
    FROM RESERVATION
    WHERE RESERVATION_ID = reservationID;

    IF reservation_exists=0 THEN
        RAISE 'reservation_id does not exist!';
    END IF;

    SELECT TRIP_ID,
           STATUS
    INTO tripid,
        prev_status
    FROM RESERVATION
    WHERE RESERVATION_ID = reservationID;

    SELECT TRIP.NO_AVAILABLE_PLACES
    INTO available_places
    FROM TRIP;

    IF prev_status = 'C' AND available_places = 0 THEN
        RAISE 'Status of reservation is "canceled" and available places equals 0';
    END IF;

    UPDATE RESERVATION
    SET STATUS = status_char
    WHERE RESERVATION_ID = reservationID;
    COMMIT;
END
$$;

CREATE OR REPLACE PROCEDURE ModifyNoPlaces4(tripID IN INTEGER, places IN INTEGER)
LANGUAGE plpgsql
AS
$$
DECLARE
    reserved_places INTEGER;
    trip_exists INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO trip_exists
    FROM TRIP
    WHERE TRIP_ID=tripId;

    IF trip_exists=0 THEN
        RAISE 'trip_id does not exist!';
    END IF;

    SELECT (NO_PLACES - NO_AVAILABLE_PLACES)
    INTO reserved_places
    FROM TRIP
    WHERE TRIP_ID = tripID;

    IF reserved_places > places THEN
        RAISE 'The Number of reserved places is bigger than entered places number';
    END IF;

    UPDATE TRIP
    SET NO_PLACES = places
    WHERE TRIP_ID = tripID;
    COMMIT;
END;
$$;