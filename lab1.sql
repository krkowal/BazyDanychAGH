CREATE TABLE PERSON
(
    PERSON_ID INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    FIRSTNAME VARCHAR2(50),
    LASTNAME  VARCHAR2(50),
    CONSTRAINT PERSON_PK PRIMARY KEY
        (
         PERSON_ID
            )
        ENABLE
);


CREATE TABLE TRIP
(
    TRIP_ID   INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    NAME      VARCHAR2(100),
    COUNTRY   VARCHAR2(50),
    TRIP_DATE DATE,
    NO_PLACES INT,
    CONSTRAINT TRIP_PK PRIMARY KEY
        (
         TRIP_ID
            )
        ENABLE
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
        ENABLE
);

CREATE TABLE COUNTRY
(
    COUNTRY_ID INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    COUNTRY    VARCHAR2(50),
    CONSTRAINT COUNTRY_PK PRIMARY KEY
        (
         COUNTRY_ID
            )
        ENABLE
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
            ENABLE;

ALTER TABLE RESERVATION
    ADD CONSTRAINT RESERVATION_FK2 FOREIGN KEY
        (
         TRIP_ID
            )
        REFERENCES TRIP
            (
             TRIP_ID
                )
            ENABLE;

ALTER TABLE RESERVATION
    ADD CONSTRAINT RESERVATION_CHK1 CHECK
        (status IN ('N', 'P', 'C'))
        ENABLE;

ALTER TABLE
    TRIP
    RENAME COLUMN
        COUNTRY
        TO
        COUNTRY_ID;

ALTER TABLE
    TRIP
    MODIFY COUNTRY_ID INT;

ALTER TABLE TRIP
    ADD CONSTRAINT TRIP_FK1 FOREIGN KEY
        (
         COUNTRY_ID
            )
        REFERENCES COUNTRY (COUNTRY_ID)
            ENABLE;


-- Person - 10 osób
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


CREATE OR REPLACE FUNCTION GetAvailablePlaces(tripId IN NUMBER)
    RETURN NUMBER
    IS
    trip_count NUMBER;
    no_places  NUMBER;
    trip_exists NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO trip_exists
    FROM TRIP
    WHERE TRIP_ID=tripId;

    IF trip_exists=0 THEN
        RAISE_APPLICATION_ERROR(-20101, 'trip_id does not exist!');
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

CREATE OR REPLACE TYPE reservation_type FORCE AS OBJECT
(
    COUNTRY        VARCHAR2(50),
    TRIP_DATE      DATE,
    NAME           VARCHAR2(100),
    FIRSTNAME      VARCHAR2(50),
    LASTNAME       VARCHAR2(50),
    RESERVATION_ID NUMBER,
    STATUS         CHAR
);
CREATE TYPE Trip_Participants_type1 AS TABLE OF reservation_type;

CREATE OR REPLACE FUNCTION TripParticipants(tripID IN NUMBER)
    RETURN Trip_Participants_type1
    IS
    tab   Trip_Participants_type1;
    trips NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO trips
    FROM TRIP
    WHERE TRIP_ID = tripID;

    IF trips = 0 THEN
        RAISE_APPLICATION_ERROR(-20101, 'trip_id does not exist!');
    END IF;
    SELECT reservation_type(
        COUNTRY,
        TRIP_DATE,
        NAME,
        FIRSTNAME,
        LASTNAME,
        R.RESERVATION_ID,
        R.STATUS
        )
    BULK COLLECT
    INTO tab
    FROM V_RESERVATIONS R
    JOIN RESERVATION R2 ON
        R.RESERVATION_ID = R2.RESERVATION_ID
    WHERE R2.TRIP_ID = tripID
        AND
        R.STATUS <> 'C';
    RETURN tab;
END;

SELECT * FROM TripParticipants(1);

CREATE OR REPLACE FUNCTION PersonReservations(personID IN NUMBER)
    RETURN Trip_Participants_type1
AS
    persons NUMBER;
    tab     Trip_Participants_type1;
BEGIN
    SELECT COUNT(*)
    INTO persons
    FROM PERSON
    WHERE PERSON_ID = personID;

    IF persons = 0 THEN
        RAISE_APPLICATION_ERROR(-20102, 'person_id does not exist!');
    END IF;

    SELECT reservation_type(
        COUNTRY,
        TRIP_DATE,
        NAME,
        P.FIRSTNAME,
        P.LASTNAME,
        R.RESERVATION_ID,
        R.STATUS) BULK COLLECT
    INTO tab
    FROM V_RESERVATIONS R
             JOIN RESERVATION R2 ON
                 R.RESERVATION_ID = R2.RESERVATION_ID
             JOIN PERSON P ON
                 P.PERSON_ID = R2.PERSON_ID
    WHERE P.PERSON_ID = personID;
    RETURN tab;
END;

SELECT * FROM PersonReservations(2);

CREATE OR REPLACE TYPE available_trips FORCE AS OBJECT
(
    COUNTRY   VARCHAR2(50),
    TRIP_DATE DATE,
    NAME           VARCHAR2(100),
    NO_PLACES           NUMBER,
    AVAILABLE_PLACES NUMBER
);
CREATE OR REPLACE TYPE available_trips_type AS TABLE OF available_trips;

CREATE OR REPLACE FUNCTION AvailableTrips(countryName IN VARCHAR2, date_from IN Date, date_to IN DATE)
    RETURN available_trips_type
AS
    tab available_trips_type;
BEGIN
    SELECT available_trips(
        T.COUNTRY,
        T.TRIP_DATE,
        T.NAME,
        T.NO_PLACES,
        T.AVAILABLE_PLACES
        ) BULK COLLECT
    INTO tab
    FROM V_AVAILABLETRIPS T
    WHERE T.COUNTRY = countryName
      AND T.TRIP_DATE BETWEEN date_from AND date_to;
    RETURN tab;
END;

SELECT *
FROM AvailableTrips('Norwegia', TO_DATE('2020-01-01','yyyy-mm-dd'),TO_DATE('2022-01-01','yyyy-mm-dd'));

CREATE OR REPLACE PROCEDURE AddReservation(tripID IN NUMBER, personID IN NUMBER)
AS
    person_exists NUMBER;
    available_places NUMBER := GetAvailablePlaces(tripID);
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
        RAISE_APPLICATION_ERROR(-20102, 'person_id does not exist!');
    END IF;

    IF available_places = 0 THEN
        RAISE_APPLICATION_ERROR(-20106, 'Cannot add new reservation because there are no places left');
    END IF;

    IF trip_date <= SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20107, 'Cannot add new reservation because the trip has already begun / ended');
    END IF;
    INSERT
    INTO RESERVATION
        (TRIP_ID, PERSON_ID, STATUS)
    VALUES (tripID, personID, 'N');
    COMMIT;
END;

BEGIN
    AddReservation(2,7);
END;

SELECT *
FROM PersonReservations(7);

CREATE OR REPLACE PROCEDURE ModifyReservationStatus(reservationID IN NUMBER, status_char IN CHAR)
AS
    trip_id NUMBER;
    prev_status CHAR(1);
    available_places NUMBER;
    reservation_exists NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO reservation_exists
    FROM RESERVATION
    WHERE RESERVATION_ID = reservationID;

    IF reservation_exists=0 THEN
        RAISE_APPLICATION_ERROR(-20103,'reservation_id does not exist!');
    END IF;

    SELECT TRIP_ID,
           STATUS
    INTO trip_id,
        prev_status
    FROM RESERVATION
    WHERE RESERVATION_ID = reservationID;

    available_places := GetAvailablePlaces(trip_id);

    IF prev_status = 'C' AND available_places = 0 THEN
        RAISE_APPLICATION_ERROR(-20105, 'Status of reservation is "canceled" and available places equals 0');
    END IF;

    UPDATE RESERVATION
    SET STATUS = status_char
    WHERE RESERVATION_ID = reservationID;
    AddReservationLog(reservationID,SYSDATE,status_char);
    COMMIT;
END;

BEGIN
    ModifyReservationStatus(23, 'P');
END;

SELECT *
FROM PersonReservations(7);

CREATE OR REPLACE PROCEDURE ModifyNoPlaces(tripID IN NUMBER, places IN NUMBER)
AS
    reserved_places NUMBER;
BEGIN
    SELECT (NO_PLACES - GetAvailablePlaces(TRIP_ID))
    INTO reserved_places
    FROM TRIP
    WHERE TRIP_ID = tripID;

    IF reserved_places > places THEN
        RAISE_APPLICATION_ERROR(-20104,'The Number of reserved places is bigger than entered places number');
    END IF;

    UPDATE TRIP
    SET NO_PLACES = places
    WHERE TRIP_ID = tripID;
    COMMIT;
END;

BEGIN
    ModifyNoPlaces(1, 7);
    ModifyNoPlaces(2, 6);
END;

SELECT *
FROM V_Trips;

BEGIN
    ModifyNoPlaces(4,1);
END;

CREATE TABLE RESERVATION_LOG
(
    LOG_ID         INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    RESERVATION_ID NUMBER,
    CHANGE_DATE    DATE,
    STATUS         CHAR(1),
    CONSTRAINT LOG_PK PRIMARY KEY (LOG_ID) ENABLE
);

ALTER TABLE RESERVATION_LOG
    ADD CONSTRAINT RESERVATION_LOG_FK1 FOREIGN KEY
        (RESERVATION_ID)
        REFERENCES RESERVATION
            (RESERVATION_ID)
            ENABLE;

ALTER TABLE RESERVATION_LOG
    ADD CONSTRAINT RESERVATION_LOG_CHK1 CHECK
        (STATUS IN ('P', 'N', 'C'))
        ENABLE;

CREATE OR REPLACE PROCEDURE AddReservationLog(reservationID IN NUMBER, insertDate IN DATE,
status_change IN CHAR)
AS
BEGIN
    INSERT
    INTO RESERVATION_LOG (RESERVATION_ID,
                          CHANGE_DATE,
                          STATUS)
    VALUES (reservationID,
            insertDate,
            status_change);
END;

BEGIN
    AddReservationLog(7, SYSDATE, 'C');
END;

SELECT *
FROM RESERVATION_LOG;

ALTER TABLE TRIP
ADD NO_AVAILABLE_PLACES NUMBER;

CREATE OR REPLACE PROCEDURE Przelicz
AS
    available_places NUMBER;
BEGIN
    FOR t IN (SELECT *
              FROM TRIP)
        LOOP
            SELECT GetAvailablePlaces(TRIP_ID)
            INTO available_places
            FROM TRIP
            WHERE TRIP_ID = t.TRIP_ID;

            UPDATE TRIP
            SET NO_AVAILABLE_PLACES = available_places
            WHERE TRIP_ID = t.TRIP_ID;
        END LOOP;
END;;

BEGIN
    Przelicz();
END;

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

CREATE OR REPLACE PROCEDURE AddReservation2(tripID IN NUMBER, personID IN NUMBER)
AS
    person_exists NUMBER;
    available_places NUMBER;
    trip_date DATE;
    trip_exists NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO trip_exists
    FROM TRIP
    WHERE TRIP_ID=tripId;

    IF trip_exists=0 THEN
        RAISE_APPLICATION_ERROR(-20101, 'trip_id does not exist!');
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
        RAISE_APPLICATION_ERROR(-20102, 'person_id does not exist!');
    END IF;

    IF available_places = 0 THEN
        RAISE_APPLICATION_ERROR(-20106, 'Cannot add new reservation because there are no places left');
    END IF;

    IF trip_date <= SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20107, 'Cannot add new reservation because the trip has already begun / ended');
    END IF;
    INSERT
    INTO RESERVATION
        (TRIP_ID, PERSON_ID, STATUS)
    VALUES (tripID, personID, 'N');
    UPDATE TRIP
    SET TRIP.NO_AVAILABLE_PLACES = TRIP.NO_AVAILABLE_PLACES -1
    WHERE TRIP.TRIP_ID = tripID;
    COMMIT;
END;

CREATE OR REPLACE PROCEDURE ModifyReservationStatus2(reservationID IN NUMBER, status_char IN CHAR)
AS
    trip_id NUMBER;
    prev_status CHAR(1);
    available_places NUMBER;
    reservation_exists NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO reservation_exists
    FROM RESERVATION
    WHERE RESERVATION_ID = reservationID;

    IF reservation_exists=0 THEN
        RAISE_APPLICATION_ERROR(-20103,'reservation_id does not exist!');
    END IF;

    SELECT TRIP_ID,
           STATUS
    INTO trip_id,
        prev_status
    FROM RESERVATION
    WHERE RESERVATION_ID = reservationID;

    SELECT TRIP.NO_AVAILABLE_PLACES
    INTO available_places
    FROM TRIP;

    IF prev_status = 'C' AND available_places = 0 THEN
        RAISE_APPLICATION_ERROR(-20105, 'Status of reservation is "canceled" and available places equals 0');
    END IF;

    UPDATE RESERVATION
    SET STATUS = status_char
    WHERE RESERVATION_ID = reservationID;

    IF status_char = 'C' AND prev_status <> 'C' THEN
        UPDATE TRIP
        SET TRIP.NO_AVAILABLE_PLACES = TRIP.NO_AVAILABLE_PLACES + 1
        WHERE TRIP.TRIP_ID = trip_id;
    ELSIF  status_char <> 'C' AND prev_status = 'C' THEN
        UPDATE TRIP
        SET TRIP.NO_AVAILABLE_PLACES = TRIP.NO_AVAILABLE_PLACES - 1
        WHERE TRIP.TRIP_ID = TRIP_ID;
    end if;

    AddReservationLog(reservationID,SYSDATE,status_char);
    COMMIT;
END;

CREATE OR REPLACE PROCEDURE ModifyNoPlaces2(tripID IN NUMBER, places IN NUMBER)
AS
    reserved_places NUMBER;
    trip_exists NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO trip_exists
    FROM TRIP
    WHERE TRIP_ID=tripId;

    IF trip_exists=0 THEN
        RAISE_APPLICATION_ERROR(-20101, 'trip_id does not exist!');
    END IF;

    SELECT (NO_PLACES - NO_AVAILABLE_PLACES)
    INTO reserved_places
    FROM TRIP
    WHERE TRIP_ID = tripID;

    IF reserved_places > places THEN
        RAISE_APPLICATION_ERROR(-20104,'The Number of reserved places is bigger than entered places number');
    END IF;

    UPDATE TRIP
    SET NO_PLACES = places
    WHERE TRIP_ID = tripID;

    UPDATE TRIP
    SET TRIP.NO_AVAILABLE_PLACES = places - TRIP.NO_PLACES + TRIP.NO_AVAILABLE_PLACES
    WHERE TRIP.TRIP_ID = tripID;
    COMMIT;
END;


CREATE OR REPLACE TRIGGER ReservationLogTrigger
    AFTER INSERT OR UPDATE
    ON RESERVATION
    FOR EACH ROW
BEGIN
    AddReservationLog(:NEW.RESERVATION_ID, SYSDATE, :NEW.STATUS);
END;

CREATE OR REPLACE TRIGGER ReservationDeletionTrigger
    BEFORE DELETE
    ON RESERVATION
BEGIN
    RAISE_APPLICATION_ERROR(-20108,'Cannot delete reservations');
END;

CREATE OR REPLACE PROCEDURE ModifyReservationStatus3(reservationID IN NUMBER, status_char IN CHAR)
AS
    trip_id NUMBER;
    prev_status CHAR(1);
    available_places NUMBER;
    reservation_exists NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO reservation_exists
    FROM RESERVATION
    WHERE RESERVATION_ID = reservationID;

    IF reservation_exists=0 THEN
        RAISE_APPLICATION_ERROR(-20103,'reservation_id does not exist!');
    END IF;

    SELECT TRIP_ID,
           STATUS
    INTO trip_id,
        prev_status
    FROM RESERVATION
    WHERE RESERVATION_ID = reservationID;

    SELECT TRIP.NO_AVAILABLE_PLACES
    INTO available_places
    FROM TRIP;

    IF prev_status = 'C' AND available_places = 0 THEN
        RAISE_APPLICATION_ERROR(-20105, 'Status of reservation is "canceled" and available places equals 0');
    END IF;

    UPDATE RESERVATION
    SET STATUS = status_char
    WHERE RESERVATION_ID = reservationID;

    IF status_char = 'C' AND prev_status <> 'C' THEN
        UPDATE TRIP
        SET TRIP.NO_AVAILABLE_PLACES = TRIP.NO_AVAILABLE_PLACES + 1
        WHERE TRIP.TRIP_ID = trip_id;
    ELSIF  status_char <> 'C' AND prev_status = 'C' THEN
        UPDATE TRIP
        SET TRIP.NO_AVAILABLE_PLACES = TRIP.NO_AVAILABLE_PLACES - 1
        WHERE TRIP.TRIP_ID = TRIP_ID;
    end if;
    COMMIT;
END;



CREATE OR REPLACE TRIGGER ReservationAdditionTrigger
    AFTER INSERT OR UPDATE
    ON RESERVATION
    FOR EACH ROW
DECLARE
    update_count NUMBER;
BEGIN
    IF (:NEW.STATUS = 'C') THEN
        IF (:OLD.STATUS <> 'C') THEN
            update_count := 1;
        END IF;
    ELSIF (:OLD.STATUS = 'C') THEN
            update_count := -1;
    ELSE
        update_count :=0;
    END IF;

    UPDATE TRIP
    SET NO_AVAILABLE_PLACES = NO_AVAILABLE_PLACES + update_count
    WHERE TRIP_ID = :NEW.TRIP_ID;
END;

CREATE OR REPLACE TRIGGER TripUpdateTrigger
    BEFORE UPDATE
    ON TRIP
    FOR EACH ROW
BEGIN
    IF (:OLD.NO_PLACES <> :NEW.NO_PLACES) THEN
        :NEW.NO_AVAILABLE_PLACES := :NEW.NO_AVAILABLE_PLACES + (:NEW.NO_PLACES - :OLD.NO_PLACES);
    END IF;
END;

CREATE OR REPLACE PROCEDURE AddReservation4(tripID IN NUMBER, personID IN NUMBER)
AS
    person_exists NUMBER;
    available_places NUMBER := GetAvailablePlaces(tripID);
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
        RAISE_APPLICATION_ERROR(-20102, 'person_id does not exist!');
    END IF;

    IF available_places = 0 THEN
        RAISE_APPLICATION_ERROR(-20106, 'Cannot add new reservation because there are no places left');
    END IF;

    IF trip_date <= SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20107, 'Cannot add new reservation because the trip has already begun / ended');
    END IF;
    INSERT
    INTO RESERVATION
        (TRIP_ID, PERSON_ID, STATUS)
    VALUES (tripID, personID, 'N');
    COMMIT;
END;


CREATE OR REPLACE PROCEDURE ModifyReservationStatus4(reservationID IN NUMBER, status_char IN CHAR)
AS
    trip_id NUMBER;
    prev_status CHAR(1);
    available_places NUMBER;
    reservation_exists NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO reservation_exists
    FROM RESERVATION
    WHERE RESERVATION_ID = reservationID;

    IF reservation_exists=0 THEN
        RAISE_APPLICATION_ERROR(-20103,'reservation_id does not exist!');
    END IF;

    SELECT TRIP_ID,
           STATUS
    INTO trip_id,
        prev_status
    FROM RESERVATION
    WHERE RESERVATION_ID = reservationID;

    available_places := GetAvailablePlaces(trip_id);

    IF prev_status = 'C' AND available_places = 0 THEN
        RAISE_APPLICATION_ERROR(-20105, 'Status of reservation is "canceled" and available places equals 0');
    END IF;

    UPDATE RESERVATION
    SET STATUS = status_char
    WHERE RESERVATION_ID = reservationID;
    COMMIT;
END;

BEGIN
    ModifyReservationStatus(23, 'P');
END;

SELECT *
FROM PersonReservations(7);

CREATE OR REPLACE PROCEDURE ModifyNoPlaces4(tripID IN NUMBER, places IN NUMBER)
AS
    reserved_places NUMBER;
BEGIN
    SELECT (NO_PLACES - GetAvailablePlaces(TRIP_ID))
    INTO reserved_places
    FROM TRIP
    WHERE TRIP_ID = tripID;

    IF reserved_places > places THEN
        RAISE_APPLICATION_ERROR(-20104,'The Number of reserved places is bigger than entered places number');
    END IF;

    UPDATE TRIP
    SET NO_PLACES = places
    WHERE TRIP_ID = tripID;
    COMMIT;
END;

