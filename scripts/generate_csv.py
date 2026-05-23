import csv, random, os
from datetime import date

STATIONS = ["ST001","ST002","ST003","ST004","ST005"]
FUELS    = [("AI95",1.85),("AI98",2.20),("DIESEL",2.10)]
OUT_DIR  = "data/incoming"
TODAY    = date.today().isoformat()

os.makedirs(OUT_DIR, exist_ok=True)

for station in STATIONS:
    fname = f"{OUT_DIR}/{station}_{TODAY}.csv"
    with open(fname, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["station_id","date","fuel_type",
                    "liters","unit_price","total_amount","operator"])
        for fuel, price in FUELS:
            liters = round(random.uniform(500, 3000), 2)
            w.writerow([station, TODAY, fuel, liters,
                        price, round(liters*price,2),
                        f"op_{random.randint(1,5):02d}"])
    print(f"✓ {fname}")
    
    
    #cd /home/nurgun/Documents/fuelco-pipeline python scripts/generate_csv.py