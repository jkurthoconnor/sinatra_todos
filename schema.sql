CREATE TABLE lists (
  id serial PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE todos (
  id serial PRIMARY KEY,
  list_id integer NOT NULL REFERENCES lists(id),
  name VARCHAR(100) NOT NULL,
  completed boolean NOT NULL DEFAULT FALSE
);
