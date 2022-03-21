from __future__ import absolute_import
from __future__ import print_function
from locust import Locust, between, TaskSet, task, events
import psycopg2
import time


def create_conn():
    return psycopg2.connect(dbname='test_pg', user='admin',
                            password='admin', host='localhost')


def execute_query(query):
    with create_conn() as conn:
        with conn.cursor() as cursor:
            cursor.execute(
                """SELECT * FROM test_ser_prop_ts
                        WHERE prop_a = 10 and prop_b = 10 
                            and ts && tstzrange(NOW(), NOW() + '10 day':: interval)""")
            records = cursor.fetchall()
            print(records)


class PsqlClient:

    def __getattr__(self, name):
        def wrapper(*args, **kwargs):
            start_time = time.time()
            try:
                res = execute_query(*args, **kwargs)
                #print('Result ----------->' + str(res.fetchone()))
                events.request_success.fire(request_type="psql",
                                            name=name,
                                            response_time=int(
                                                (time.time() - start_time) * 1000),
                                            response_length=res.rowcount)
            except Exception as e:
                events.request_failure.fire(request_type="psql",
                                            name=name,
                                            response_time=int(
                                                (time.time() - start_time) * 1000),
                                            exception=e)

                print('error {}'.format(e))

        return wrapper


class CustomTaskSet(TaskSet):
    conn_string = 'employee-metrics:employee-metrics@emp1-metrics-db-1/emp'

    @task(1)
    def execute_query(self):
        self.client.execute_query(
            "select * from employees where date_of_birth like '%Jan%'")

# This class will be executed when you fire up locust


class PsqlLocust(Locust):
    min_wait = 0
    max_wait = 0
    task_set = CustomTaskSet
    wait_time = between(min_wait, max_wait)

    def __init__(self):
        super()
        self.client = PsqlClient()
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
