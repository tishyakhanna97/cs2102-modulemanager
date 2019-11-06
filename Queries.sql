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
	WHEN SQLSTATE '23502' THEN -- pkey error
		RAISE EXCEPTION 'Error: some of the required fields are missing';
		ROLLBACK;
	WHEN SQLSTATE '23503' THEN  -- fkey error
		RAISE EXCEPTION 'Error: an inaccurate major name has been entered';
		ROLLBACK;
	WHEN SQLSTATE '23505' THEN  -- 
		RAISE EXCEPTION 'Error: account with this ID has existed';
		ROLLBACK;
END;
$csu$ LANGUAGE plpgsql;

				       
-- Trigger to ensure that preclusions are added in pairs.				       
CREATE OR REPLACE FUNCTION dual_preclusion()
RETURNS TRIGGER AS
$a_p$
BEGIN
	IF TG_OP = 'DELETE' 
	THEN 
		IF EXISTS (SELECT 1
				FROM Preclusions P 
				WHERE P.modcode = old.precluded AND P.precluded = old.modcode
		       )
		THEN	   
			DELETE FROM Preclusions PP
			WHERE PP.modcode = old.precluded AND PP.precluded = old.modcode;
			RETURN NULL;
		ELSE
			RETURN NULL;
		END IF;
	ELSEIF NOT EXISTS (SELECT 1
			   FROM Preclusions P1
			   WHERE P1.modcode = new.precluded AND P1.precluded = new.modcode
			  ) 
	THEN	
		INSERT INTO Preclusions VALUES(new.precluded, new.modcode);
		RETURN NULL;
	ELSE 
		RETURN NULL;
	END IF;
END;
$a_p$ LANGUAGE plpgsql;
CREATE TRIGGER add_preclusion
AFTER INSERT OR DELETE ON Preclusions
FOR EACH ROW
EXECUTE PROCEDURE dual_preclusion();

-- compute the workload for a student      do not count audit modules      return error if student doesn't exist 
-- params: id of a student  return: int workload   
CREATE OR REPLACE FUNCTION compute_workload(id varchar(50)) 
RETURNS int AS
$c_w$
BEGIN
	IF NOT EXISTS (SELECT 1 FROM Students S WHERE S.uid = id)
	THEN
		RAISE EXCEPTION 'Error: this student does not exist';
	END IF;
	RETURN COALESCE((SELECT SUM(workload)
		  	FROM modules M 
			WHERE EXISTS (SELECT 1
						  FROM Gets G
			              WHERE G.uid = id AND M.modcode = G.modcode AND NOT G.is_audit  
						 )
			), 0);
END;
$c_w$ LANGUAGE plpgsql;
