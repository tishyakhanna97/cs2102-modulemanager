--- SQL Query ---

--- Create/Update/Delete Lecture ---
--- Create Lecture --- Module must exist before lecture can be created
--- Query does nothing if Lectures modcode doesnt exist in module
DO
$do$
BEGIN
IF EXISTS (SELECT FROM modules where modcode = modcode) THEN
   INSERT INTO lectures values (lnum,modcode,deadline,quota);
ELSE 
END IF;
END
$do$

--- Create Lecture SLOT --- Check lecture modcode and lnum must exists
DO
$do$
BEGIN
IF EXISTS (SELECT FROM lectures l where l.modcode = modcode AND l.lnum = lnum) THEN
   INSERT INTO slots values (lnum,modcode,t_start,t_end,day);
ELSE 
END IF;
END
$do$

--- Update Lecture --- Don't allow update
--- Update Lecture SLOT --- Don't allow update

--- Delete Lecture --- (Base on ModuleCode, LectureNo)
DO
$do$
BEGIN
IF EXISTS (SELECT FROM lectures l where l.modcode = modcode AND l.lnum = lnum) THEN
   DELETE FROM lectures where modcode = modcode AND lnum = lnum;
ELSE 
END IF;
END
$do$

--- Delete Lecture SLOT --- (Base on ModuleCode, LectureNo, Day)
DO
$do$
BEGIN
IF EXISTS (SELECT FROM slots t where t.modcode = modcode AND t.lnum = lnum AND t.day = day) THEN
   DELETE FROM slots where modcode = modcode AND lnum = lnum AND day = day;
ELSE 
END IF;
END
$do$

--- Admin list all lecture base on search result (module name)
SELECT * FROM lectures where modcode = modcode

--- Admin list all lecture slot base either search result (module name)
SELECT * from slots where modcode = modcode or lnum = lnum or day = day



--- Functions, Triggers and Procedure ----

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



-- Use this to ensure that every student has at least one major/add students into the db
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
			              WHERE G.uid = id AND M.modcode = G.modcode   
						 )
			), 0);
END;
$c_w$ LANGUAGE plpgsql;

				       
/* This function checks, among the modules that the given student (identified by id) is taking, which clashes with the given lecture slot
(identify by l, code ~ lnum, modcode).
   We assume that at this point the id is guaranteed to refer to a student
*/
CREATE OR REPLACE FUNCTION time_clash(id varchar(100), l integer, code varchar(100)) 
RETURNS SETOF varchar(100) AS
$t_c$
BEGIN
	RETURN QUERY  -- Find a module M that
		(SELECT M.modcode 
		 FROM Modules M
		 WHERE  
		 		-- Clashes with the current lecture slot
		 		
		 EXISTS (SELECT 1 -- The first condition will check all the module that clashes with the lecture slot.  
		      	 FROM Slots L1 JOIN Slots L2 ON ((L1.modcode, L1.lnum) <> (L2.modcode, L2.lnum) AND (L1.modcode, L1.lnum) = (code, l) AND L2.modcode = M.modcode)
				                       -- Test for time overlapping   
				 WHERE L1.d = L2.d AND ((L1.t_end > L2.t_start AND L2.t_start > L1.t_start) OR (L2.t_end > L1.t_start AND L1.t_start > L2.t_start))
				 AND --  And is taken by id
			     -- Check if this module is indeed taken by the student											
			     EXISTS (SELECT 1 
					     FROM Gets G
		 			     WHERE G.uid = id AND G.modcode = L2.modcode AND G.lnum = L2.lnum 
		 		        )
		       )
		);		 
	RETURN;
END
$t_c$ LANGUAGE plpgsql;
				       
				       
				      				       
-- This trigger is fired for addition that results in a cycle and will delete the triggering entry with detailed warning provided				       
CREATE OR REPLACE FUNCTION remove_cyclic_prereq()
RETURNS TRIGGER AS
$rcp$
BEGIN
	IF EXISTS 
	  (WITH RECURSIVE Preq(want, need) AS (
		SELECT want, need FROM Prerequisites
		UNION
		SELECT P.want, Pr.need
		FROM Preq P, Prerequisites Pr
		WHERE P.need = Pr.want
	       )
	        SELECT 1 FROM Preq P  
	 		 WHERE P.need = P.want 
	   )
	THEN
		DELETE FROM Prerequisites P WHERE P.want = new.want AND P.need = new.need; 
		RAISE NOTICE 'Error: adding % as a prerequisite for % results in a cyclic dependency', new.want, new.need;
	RETURN NULL;
	END IF;
END;
$rcp$ LANGUAGE plpgsql;
CREATE TRIGGER detect_cycle
AFTER INSERT ON Prerequisites
FOR EACH ROW
EXECUTE PROCEDURE remove_cyclic_prereq()
				       
-- DFS to find all the modules to be completed for student (id) to qualify for the module (wantt)				       
CREATE OR REPLACE FUNCTION DFS_fulfill(id varchar(100), wantt varchar(100), need varchar(100)[])
RETURNS varchar(100)[] AS
$DFS$
DECLARE
	r record;
	mc varchar(100);
	
BEGIN
	-- The hierarchy is a DAG so there is no need to flag visited node
	FOR r IN (SELECT * FROM Prerequisites PP where PP.want = wantt) LOOP
		mc := r.need;
		IF mc = ANY(DFS_fulfill(id, mc, need)) AND mc != ALL(need)
		THEN
			need := need || mc;
		END IF;
	END LOOP;
	IF NOT EXISTS (SELECT 1
				   FROM Completions C
				   WHERE C.modcode = wantt and C.uid = id
				  )
	THEN
		need := need || wantt;
	END IF;
	RETURN need;
END; 
$DFS$ LANGUAGE plpgsql

-- The function that we use on the interface
CREATE OR REPLACE FUNCTION findNeededModules(id varchar(100), modcode varchar(100))
RETURNS text AS
$n$
DECLARE
	arr varchar(100)[];
BEGIN
	arr := DFS_fulfill(id, modcode, '{}');
	arr := arr[0:array_length(arr, 1)-1];
	RETURN array_to_string(arr,', ');
END;
$n$ LANGUAGE plpgsql;
		    
		    
--Compute the year of the student assuming there is one in the DB		    
CREATE OR REPLACE FUNCTION compute_year(id varchar(100))
RETURNS numeric AS
$cy$
BEGIN
	RETURN ROUND(EXTRACT(epoch from(now() - (SELECT enroll
				   			  FROM Students S
							  WHERE S.uid = id
				    ))/31557600)::numeric, 2);
END;
$cy$ LANGUAGE plpgsql;

-- The huge trigger
CREATE OR REPLACE FUNCTION handle_bid()
RETURNS TRIGGER AS 
$hb$
BEGIN
	--if admin made the bid then all checks are bypassed
	IF EXISTS (SELECT 1
			   FROM Admins A
			   WHERE A.uid = new.uid_req 
			  )
	THEN
		INSERT INTO Gets VALUES (new.uid, new.modcode, new.lnum, false);
		RETURN (new.uid, new.uid_req, new.modcode, new.lnum, new.bid_time, True , 'Module added by an admin.'::varchar(100));	
	ELSIF (new.uid_req <> new.uid) -- A student can only bid for herself
	THEN
		RAISE EXCEPTION 'Error: mismatching IDs';
		RETURN NULL;
		
	-- Check if the student had completed the module before or a preclusion
	ELSIF EXISTS (SELECT 1 
				  FROM Completions C 
				  WHERE C.uid  = new.uid AND C.modcode = new.modcode 
				 )
		  OR
		  EXISTS (SELECT 1
				  FROM Completions C
				  WHERE C.uid = new.uid 
				  AND EXISTS (SELECT 1 
							  FROM Preclusions P
							  WHERE P.modcode = new.modcode AND C.modcode = P.precluded 
							 )
				 )
	THEN 
		RETURN (new.uid, new.uid_req, new.modcode, new.lnum, new.bid_time, False , 'Module/preclusion completed before'::varchar(100));
	-- Check if the student has all prerequisites completed
	ELSIF EXISTS (SELECT 1 
				  FROM Prerequisites P
				  WHERE P.want = new.modcode 
				  AND NOT EXISTS (SELECT 1
				  				  FROM Completions C
								  WHERE C.modcode = P.need AND C.uid = new.uid 
				  				 )
	  			 )
	THEN 
		RETURN (new.uid, new.uid_req, new.modcode, new.lnum, new.bid_time, False , 'Uncompleted prerequisites'::varchar(100));
	-- Check if the student made request before deadline	
	ELSIF new.bid_time > (SELECT deadline 
						  FROM Lectures L
						  WHERE L.lnum = new.lnum AND L.modcode = new.modcode)
	THEN 
		RETURN (new.uid, new.uid_req, new.modcode, new.lnum, new.bid_time, False , 'Request made after deadline'::varchar(100));
	
	-- Check for quota
	ELSIF (SELECT COUNT(DISTINCT G.uid) 
		   FROM Gets G 
		   WHERE G.lnum = new.lnum AND G.modcode = new.modcode AND G.uid <> new.uid
		  ) >= (SELECT L.quota 
			   FROM Lectures L
			   WHERE L.lnum = new.lnum AND L.modcode = new.modcode
			  )
	THEN 
		RETURN (new.uid, new.uid_req, new.modcode, new.lnum, new.bid_time, False , 'Quota exceeded'::varchar(100));
	
	-- Then whether they have maximum workload
	ELSIF (SELECT SS.total
			FROM (SELECT S.uid, COALESCE(SUM(GM.workload),0) AS total
	  		      FROM Students S 
      			  LEFT JOIN (Gets G NATURAL JOIN Modules M) AS GM 
	  			  ON GM.uid = S.uid 
                  GROUP BY S.uid) AS SS
            WHERE SS.uid = new.uid) - compute_year(new.uid) > 23
	THEN
		RETURN (new.uid, new.uid_req, new.modcode, new.lnum, new.bid_time, False , 'Maximum workload exceeded'::varchar(100));
	 
	ELSE
		RETURN (new.uid, new.uid_req, new.modcode, new.lnum, new.bid_time, True , 'Module successfully added'::varchar(100));
	
	END IF;
	
	EXCEPTION
		WHEN SQLSTATE '23503' THEN
			RAISE EXCEPTION 'Error: The lecture slot does not exist ';
		WHEN SQLSTATE '23505' THEN
			RAISE EXCEPTION 'Error: This slot is already allocated to the student';
END;
$hb$ LANGUAGE plpgsql;
CREATE TRIGGER add_bid
BEFORE INSERT ON Bids
FOR EACH ROW
EXECUTE PROCEDURE handle_bid();
