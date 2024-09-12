CREATE TABLE users (
    id INT PRIMARY KEY,
    name TEXT,
    pwd TEXT
);

CREATE TABLE scores (
    id INT PRIMARY KEY,
    user_id INT,
    score INT,
    date DATETIME
);

CREATE TABLE person (
    id INT PRIMARY KEY,
    name TEXT,
    img_url TEXT,
);

CREATE TABLE set (
    id INT PRIMARY KEY,
    name TEXT,
);

CREATE TABLE rel_person_set (
    person_id INT,
    set_id INT,
)