CREATE TABLE Users (
	uid varchar(100) PRIMARY KEY,
	password varchar(100) NOT NULL,
	is_super boolean DEFAULT False NOT NULL
);
CREATE TABLE Admins (
	uid varchar(100) PRIMARY KEY,
	name varchar(100),
	contact varchar(100), -- Can display relevant people in-charge
	FOREIGN KEY (uid) REFERENCES Users ON DELETE CASCADE
);

CREATE TABLE Students (
	uid varchar(100) PRIMARY KEY,
	name varchar(100) NOT NULL,
	--Remove cap, it's hard to calculate. cap numeric DEFAULT 0 ,
	enroll DATE NOT NULL,
	FOREIGN KEY (uid) REFERENCES Users ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Exchanges (
	uid varchar(100) PRIMARY KEY,
	home_country varchar(100) NOT NULL,
	FOREIGN KEY (uid) REFERENCES Students ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Faculties (
	fname varchar(100) PRIMARY KEY
);

CREATE TABLE Minors (
	min_name varchar(100) PRIMARY KEY,
	fname varchar(100) DEFAULT 'NUS' NOT NULL REFERENCES Faculties ON DELETE SET DEFAULT -- minor belongs to
);

CREATE TABLE Majors (
	maj_name varchar(100) PRIMARY KEY,
	fname varchar(100) DEFAULT 'NUS' NOT NULL REFERENCES Faculties ON DELETE SET DEFAULT -- major belongs to
);
--Has minor
CREATE TABLE Minoring (
	uid varchar(100) NOT NULL REFERENCES Students ON DELETE CASCADE ON UPDATE CASCADE,
	min_name varchar(100) NOT NULL REFERENCES Minors ON DELETE CASCADE ON UPDATE CASCADE,
	PRIMARY KEY (uid,min_name)
);
--Has major   trigger needed to ensure that each student has a major
CREATE TABLE Majoring (
	uid varchar(100) NOT NULL REFERENCES Students ON DELETE CASCADE ON UPDATE CASCADE 
		DEFERRABLE INITIALLY DEFERRED,
	maj_name varchar(100) NOT NULL REFERENCES Majors ON DELETE CASCADE ON UPDATE CASCADE,
	PRIMARY KEY (uid,maj_name)
);

CREATE TABLE Modules (
	modcode varchar(100) PRIMARY KEY,
	modname varchar(100) NOT NULL,
	fname varchar(100) DEFAULT 'NUS' NOT NULL REFERENCES Faculties ON DELETE SET DEFAULT, -- faculty owns a module,
	workload int NOT NULL
);

CREATE TABLE Lectures (
	lnum int NOT NULL,
	modcode varchar(100) NOT NULL REFERENCES Modules ON DELETE CASCADE, -- module covers the slot
	deadline timestamp with time zone NOT NULL,
	quota int DEFAULT 100 NOT NULL,
	PRIMARY KEY(lnum,modcode)
);

-- Weak entity Slots created to represent the time slots for each lecture slot.
CREATE TYPE mood AS ENUM ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday');

CREATE TABLE Slots (
	lnum integer,
	modcode varchar(100),
	d mood,
	t_start time,
	t_end time,
	FOREIGN KEY (lnum, modcode) REFERENCES Lectures,
	PRIMARY KEY(lnum, modcode, d),
	CHECK (t_start < t_end)
);

-- make sure that mood is defined


CREATE TABLE Prerequisites(
	modcode varchar(100) NOT NULL REFERENCES Modules ON DELETE CASCADE,
	prereq varchar(100) NOT NULL REFERENCES Modules ON DELETE CASCADE CHECK(prereq <> modcode),
	PRIMARY KEY(modcode,prereq)
);

CREATE TABLE Preclusions(
	modcode varchar(100) NOT NULL REFERENCES Modules ON DELETE CASCADE,
	precluded varchar(100) NOT NULL REFERENCES Modules ON DELETE CASCADE CHECK(precluded <> modcode),
	PRIMARY KEY(modcode,precluded)
); -- trigger here to add preclusion in opposite direction

CREATE TABLE Bids(
	uid varchar(100) NOT NULL REFERENCES Students,
	uid_req varchar(100) NOT NULL REFERENCES Students,
	modcode varchar(100) NOT NULL,
	lnum int NOT NULL,
	bid_time timestamp with time zone,
	status boolean DEFAULT True,
	remark varchar(100) DEFAULT 'Successful bid!',
	FOREIGN KEY (lnum,modcode) REFERENCES Lectures ON DELETE CASCADE ON UPDATE CASCADE,
	PRIMARY KEY(uid, uid_req, modcode,lnum,bid_time)
); -- Bids

CREATE TABLE Gets(
	uid varchar(100) NOT NULL REFERENCES Students ON DELETE CASCADE ON UPDATE CASCADE,
	modcode varchar(100) NOT NULL,
	lnum int NOT NULL,
	FOREIGN KEY (lnum,modcode) REFERENCES Lectures ON DELETE CASCADE ON UPDATE CASCADE,
	PRIMARY KEY(uid,modcode,lnum)
);

CREATE TABLE Completions(
	uid varchar(100) NOT NULL,
	modcode varchar(100) NOT NULL REFERENCES Modules ON UPDATE CASCADE,
	PRIMARY KEY(uid, modcode)
);

INSERT INTO Users VALUES ('sample','sample');
