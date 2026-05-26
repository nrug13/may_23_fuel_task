docker exec -i postgres-db psql -U nurgun -d mydb < scripts/init_db.sql
docker exec -it postgres-db psql -U nurgun -d mydb
\d raw.fuel_sales
INSERT INTO raw.fuel_sales 
  (station_id, sale_date, fuel_type, liters, unit_price, total_amount, operator)
VALUES 
  ('ST001', '2026-05-23', 'AI95', 1369.35, 1.85, 2533.30, 'op_02');
  eynisini ikinci defe run edende 
  ERROR:  duplicate key value violates unique constraint "uix_fuel_sales"
DETAIL:  Key (station_id, sale_date, fuel_type)=(ST001, 2026-05-23, AI95) already exists.

INSERT INTO raw.fuel_sales 
  (station_id, sale_date, fuel_type, liters, unit_price, total_amount, operator)
VALUES 
  ('ST001', '2026-05-23', 'AI95', 1369.35, 1.85, 2533.30, 'op_02')
ON CONFLICT (station_id, sale_date, fuel_type) DO NOTHING;

bunda ise error olmur






