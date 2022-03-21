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

--- TIMESTAMP + ID + PROPERTY TABLES
CREATE TABLE test_ser_prop_ts(
  id SERIAL,
  ts tstzrange NOT NULL,
  prop_a BIGINT NOT NULL,
  prop_b BIGINT NOT NULL,
  EXCLUDE USING gist (ts WITH &&, prop_a WITH =, prop_b WITH =)
);

CREATE INDEX test_ser_prop_ts_ts ON test_ser_prop_ts USING GIST (ts);
CREATE INDEX test_ser_prop_ts_prop_a ON test_ser_prop_ts (
  prop_a,
  prop_b
);

CREATE TABLE test_ser_prop_no_ts(
  id SERIAL,
  start_ts TIMESTAMP NOT NULL,
  end_ts TIMESTAMP NOT NULL,
  prop_a BIGINT NOT NULL,
  prop_b BIGINT NOT NULL
);

CREATE UNIQUE INDEX test_ser_prop_no_ts_unique ON test_ser_prop_no_ts (
  start_ts asc, 
  end_ts desc,
  prop_a,
  prop_b
);

CREATE INDEX test_ser_prop_no_ts_ts ON test_ser_prop_no_ts (
  start_ts asc, 
  end_ts desc
);
CREATE INDEX test_ser_prop_no_ts_props ON test_ser_prop_no_ts (
  prop_a,
  prop_b
);


-- FILL

INSERT INTO test_ser_prop_no_ts(start_ts, end_ts, prop_a, prop_b)
select start_ts, end_ts, a, b from test_no_ts
CROSS JOIN generate_series(1,50) a
CROSS JOIN generate_series(1,200) b;

INSERT INTO test_ser_prop_ts(ts, prop_a, prop_b)
select ts, a, b from test_ts
CROSS JOIN generate_series(1,50) a
CROSS JOIN generate_series(1,200) b;

VACUUM FULL;


explain analyze verbose
SELECT * FROM test_ser_prop_ts
WHERE prop_a = 10 and prop_b = 10 and ts && tstzrange(NOW(), NOW() + '10 day':: interval);

explain analyze
SELECT * FROM test_ser_prop_no_ts
WHERE prop_a = 10 and prop_b = 10 and end_ts > NOW() and start_ts < NOW() + '10 day':: interval;