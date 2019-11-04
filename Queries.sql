-- Query to ensure that data is encrypted before being stored in the record
CREATE EXTENSION pgcrypto;
CREATE OR REPLACE FUNCTION hash_proc()
RETURNS TRIGGER AS 
$aab$
BEGIN 
	IF (TG_OP = 'UPDATE') AND crypt(NEW.password, gen_salt('bf'))::varchar(100) = OLD.password::varchar(100)
	THEN RETURN NEW;
	ELSE
		RETURN (NEW.uid, crypt(NEW.password, gen_salt('bf'))::varchar(100), NEW.is_super);
	END IF;
END;
$aab$ LANGUAGE plpgsql;
CREATE TRIGGER add_user 
BEFORE INSERT OR UPDATE ON Users
FOR EACH ROW 
EXECUTE PROCEDURE hash_proc();



-- Use this to ensure that every student has at least one major
CREATE OR REPLACE PROCEDURE create_student_user(
	uid varchar(100) DEFAULT NULL, 
	pw varchar(100) DEFAULT NULL, 
	name varchar(100) DEFAULT NULL, 
	enroll date DEFAULT NULL, 
	major varchar(100) DEFAULT NULL, 
	country varchar(100) DEFAULT 'LOCAL') 
AS
$csu$
BEGIN
	INSERT INTO Users VALUES (uid, pw, False);
	INSERT INTO Students VALUES (uid, name, enroll);
	INSERT INTO Majoring VALUES (uid, major);
	-- If the country field is set to anything other than default then we add an exchange entity
	IF country <> 'LOCAL'
	THEN INSERT INTO Exchanges VALUES (uid, country);
	END IF;
EXCEPTION
	WHEN SQLSTATE '23502' THEN
		RAISE EXCEPTION 'Error: some of the required fields are missing';
		ROLLBACK;
	WHEN SQLSTATE '23503' THEN
		RAISE EXCEPTION 'Error: an inaccurate major name has been entered';
		ROLLBACK;
	WHEN SQLSTATE '23505' THEN
		RAISE EXCEPTION 'Error: account with this ID has existed';
		ROLLBACK;
END;
$csu$ LANGUAGE plpgsql;