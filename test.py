import psycopg2


with psycopg2.connect(dbname='test_pg', user='admin',
                      password='admin', host='localhost') as conn:
    with conn.cursor() as cursor:
        cursor.execute('select * from test_ser_prop_ts order by ts limit 10;')
        records = cursor.fetchall()
        print(records)


# explain analyze verbose
# SELECT * FROM test_ser_prop_ts
# WHERE prop_a = 10 and ts & & tstzrange(NOW(), NOW() + '10 day': : interval)
#
#
# explain analyze
# SELECT * FROM test_ser_prop_no_ts
# WHERE prop_a = 10 and end_ts > NOW() and start_ts < NOW() + '10 day':: interval
#
# explain analyze verbose
# SELECT * FROM test_ser_prop_ts
# WHERE ts & & tstzrange(NOW(), NOW() + '10 day': : interval)
#
# explain analyze
# SELECT * FROM test_ser_prop_no_ts
# WHERE end_ts > NOW() and start_ts < NOW() + '10 day':: interval
