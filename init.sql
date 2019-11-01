CREATE TABLE web_user (
    username VARCHAR PRIMARY KEY NOT NULL,
    preferred_name VARCHAR,
    password VARCHAR NOT NULL
);

CREATE TABLE Users (
    account VARCHAR PRIMARY KEY,
    password VARCHAR NOT NULL
);

CREATE TABLE Admin (
    account VARCHAR PRIMARY KEY,
    name VARCHAR NOT NULL,
    FOREIGN KEY(account) references Users
    ON DELETE CASCADE
    ON UPDATE CASCADE
    );

CREATE TABLE Students (
    account VARCHAR PRIMARY KEY,
    name varchar NOT NULL,
    enroll_year integer NOT NULL,
    cap float NOT NULL,
    FOREIGN KEY(account) references Users
    ON DELETE CASCADE
    ON UPDATE CASCADE
);


CREATE Table Exchange_Students (
    account VARCHAR PRIMARY KEY,
    name varchar NOT NULL,
    enroll_year integer NOT NULL,
    cap float NOT NULL,
    home_country varchar NOT NULL,
    FOREIGN KEY(account) references Users
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

CREATE TABLE Minor (
    minor_name VARCHAR NOT NULL
);


