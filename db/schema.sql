CREATE TABLE users (
    id INT PRIMARY KEY,
    name TEXT,
    pwd TEXT,
    admin BOOLEAN
);

CREATE TABLE scores (
    id INT PRIMARY KEY,
    user_id INT,
    score INT,
    date DATETIME
);

CREATE TABLE people (
    id INT PRIMARY KEY,
    name TEXT,
    gender TEXT,
    img_url TEXT,
    set_id INT
);

CREATE TABLE herrings (
    id INT PRIMARY KEY,
    name TEXT,
    gender TEXT,
    set_id INT
);

CREATE TABLE sets (
    id INT PRIMARY KEY,
    name TEXT
);