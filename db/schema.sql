CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT,
    pwd TEXT,
    admin BOOLEAN
);

CREATE TABLE scores (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,
    score REAL,
    date DATETIME,
    set_id INTEGER
);

CREATE TABLE people (
    id INTEGER PRIMARY KEY,
    name TEXT,
    gender TEXT,
    img_url TEXT,
    set_id INTEGER
);

CREATE TABLE herrings (
    id INTEGER PRIMARY KEY,
    name TEXT,
    gender TEXT,
    set_id INTEGER
);

CREATE TABLE sets (
    id INTEGER PRIMARY KEY,
    name TEXT
);