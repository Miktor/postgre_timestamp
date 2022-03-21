CREATE EXTENSION IF NOT EXISTS btree_gist;

--- ONLY TIMESTAMP TABLES
CREATE TABLE test_no_ts(
  start_ts TIMESTAMP NOT NULL,
  end_ts TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX test_no_ts_unique ON test_no_ts (start_ts asc, end_ts desc);

CREATE TABLE test_ts(
  ts tstzrange
);

CREATE UNIQUE INDEX test_ts_unique ON test_ts (ts);

-- FILL

INSERT INTO test_no_ts(start_ts, end_ts)
SELECT NOW() + i * 2 * '1 day'::interval,
       NOW() + (i * 2 + 1) * '1 day'::interval
FROM   generate_series(1,100) i;

insert into test_ts
select tstzrange(start_ts, end_ts) from test_no_ts;

--- TIMESTAMP + ID TABLES
CREATE TABLE test_ser_no_ts(
  id SERIAL,
  start_ts TIMESTAMP NOT NULL,
  end_ts TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX test_ser_no_ts_unique ON test_ser_no_ts (start_ts asc, end_ts desc);

CREATE TABLE test_ser_ts(
  id SERIAL, 
  ts tstzrange
);

CREATE UNIQUE INDEX test_ser_ts_unique ON test_ser_ts (ts);

-- FILL

INSERT INTO test_ser_no_ts(start_ts, end_ts)
select start_ts, end_ts from test_no_ts;

insert into test_ser_ts (ts)
select ts from test_ts;

--- TIMESTAMP + ID + PROPERTY TABLES
CREATE TABLE test_ser_prop_ts(
  id SERIAL,
  ts tstzrange NOT NULL,
  prop_a BIGINT NOT NULL
);

CREATE INDEX test_ser_prop_ts_ts ON test_ser_prop_ts USING GIST (ts);
CREATE INDEX test_ser_prop_ts_prop_a ON test_ser_prop_ts (prop_a);

CREATE TABLE test_ser_prop_no_ts(
  id SERIAL,
  start_ts TIMESTAMP NOT NULL,
  end_ts TIMESTAMP NOT NULL,
  prop_a BIGINT NOT NULL
);

CREATE UNIQUE INDEX test_ser_prop_no_ts_unique ON test_ser_prop_no_ts (start_ts asc, end_ts desc, prop_a);


-- FILL

INSERT INTO test_ser_prop_no_ts(start_ts, end_ts, prop_a)
select start_ts, end_ts, i from test_no_ts
CROSS JOIN generate_series(1,1000) i;

INSERT INTO test_ser_prop_ts(ts, prop_a)
select ts, i from test_ts
CROSS JOIN generate_series(1,1000) i;