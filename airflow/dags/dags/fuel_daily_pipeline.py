from airflow import DAG
from airflow.operators.python import PythonOperator, ShortCircuitOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.utils.dates import days_ago
from datetime import timedelta
import os, csv, logging

DATA_DIR = "/opt/airflow/data/incoming"
STATIONS = ["ST001","ST002","ST003","ST004","ST005"]
PG_CONN  = "fuelco_postgres"

def check_files(**ctx):
    run_date = ctx["ds"]
    missing = [s for s in STATIONS
               if not os.path.exists(f"{DATA_DIR}/{s}_{run_date}.csv")]
    if missing:
        logging.warning(f"CSV tapilmadi: {missing}")
        return False
    logging.info("Butun CSV-ler movcuddur")
    return True

def load_raw(**ctx):
    run_date = ctx["ds"]
    hook = PostgresHook(postgres_conn_id=PG_CONN)
    sql = """
        INSERT INTO raw.fuel_sales
            (station_id, sale_date, fuel_type, liters,
             unit_price, total_amount, operator, source_file)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
        ON CONFLICT (station_id, sale_date, fuel_type) DO NOTHING
    """
    inserted = 0
    for station in STATIONS:
        path = f"{DATA_DIR}/{station}_{run_date}.csv"
        if not os.path.exists(path):
            continue
        with open(path) as f:
            for row in csv.DictReader(f):
                hook.run(sql, parameters=(
                    row["station_id"], row["date"], row["fuel_type"],
                    row["liters"], row["unit_price"],
                    row["total_amount"], row["operator"],
                    os.path.basename(path)))
                inserted += 1
    logging.info(f"Yuklendi: {inserted} setir")

def transform_to_mart(**ctx):
    run_date = ctx["ds"]
    hook = PostgresHook(postgres_conn_id=PG_CONN)
    hook.run("""
        INSERT INTO mart.daily_station_summary
            (station_id, sale_date, total_liters, total_revenue,
             top_fuel, transaction_cnt, updated_at)
        SELECT station_id, sale_date,
               SUM(liters), SUM(total_amount),
               (SELECT fuel_type FROM raw.fuel_sales r2
                WHERE r2.station_id = r.station_id
                  AND r2.sale_date  = r.sale_date
                ORDER BY liters DESC LIMIT 1),
               COUNT(*), NOW()
        FROM raw.fuel_sales r
        WHERE sale_date = %(d)s
        GROUP BY station_id, sale_date
        ON CONFLICT (station_id, sale_date) DO UPDATE SET
            total_liters  = EXCLUDED.total_liters,
            total_revenue = EXCLUDED.total_revenue,
            updated_at    = NOW()
    """, parameters={"d": run_date})
    logging.info(f"Mart guncellendi: {run_date}")

def validate_mart(**ctx):
    run_date = ctx["ds"]
    hook = PostgresHook(postgres_conn_id=PG_CONN)
    cnt, revenue = hook.get_records(
        "SELECT COUNT(*), SUM(total_revenue) "
        "FROM mart.daily_station_summary WHERE sale_date = %s",
        parameters=[run_date])[0]
    assert cnt == len(STATIONS), f"Stansiya sayi yanlis: {cnt}"
    assert revenue > 0, "Gelir 0 — data problemi!"
    logging.info(f"Validasiya OK — {cnt} stansiya, {revenue:.2f} AZN")

with DAG(
    dag_id       = "fuel_daily_pipeline",
    schedule     = "30 23 * * *",
    start_date   = days_ago(1),
    catchup      = False,
    default_args = {
        "owner"      : "data-team",
        "retries"    : 2,
        "retry_delay": timedelta(minutes=5),
    },
    tags = ["fuelco", "etl", "daily"],
) as dag:

    t1 = ShortCircuitOperator(task_id="check_csv_files",  python_callable=check_files)
    t2 = PythonOperator(task_id="load_raw",               python_callable=load_raw)
    t3 = PythonOperator(task_id="transform_to_mart",      python_callable=transform_to_mart)
    t4 = PythonOperator(task_id="validate_mart",          python_callable=validate_mart)

    t1 >> t2 >> t3 >> t4