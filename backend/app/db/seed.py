import uuid
from datetime import datetime, date, timezone
from app.db.session import SessionLocal
from app.models.recycler import Recycler
from app.models.price import Price
from app.models.collector import Collector
from app.core.security import hash_pin

def seed():
    db = SessionLocal()
    
    # 1. Seed Recyclers
    print("Seeding recyclers...")
    SEED_RECYCLERS = [
        {
            "name": "Eco Recyclers Pvt Ltd",
            "facility_address": "MIDC Turbhe, Navi Mumbai",
            "latitude": 19.0728,
            "longitude": 73.0183,
            "materials_accepted": ["PCB", "Cable", "Battery", "LCD"],
            "auth_number": "MH-CPCB-2024-0021",
            "auth_status": "Active",
            "offered_rates": {"PCB": 210, "Cable": 85, "Battery": 45, "LCD": 30},
            "pickup_available": True,
            "service_radius_km": 30,
            "verified_by_admin": True
        },
        {
            "name": "Pune E-Waste Solutions",
            "facility_address": "Hinjewadi IT Park, Pune",
            "latitude": 18.5913,
            "longitude": 73.7389,
            "materials_accepted": ["CRT", "Motor", "Plastic", "Mixed", "PCB"],
            "auth_number": "MH-CPCB-2024-0055",
            "auth_status": "Active",
            "offered_rates": {"CRT": 10, "Motor": 50, "Plastic": 15, "Mixed": 25, "PCB": 190},
            "pickup_available": True,
            "service_radius_km": 40,
            "verified_by_admin": True
        },
        {
            "name": "Nashik Green Tech",
            "facility_address": "Ambad MIDC, Nashik",
            "latitude": 19.9678,
            "longitude": 73.7431,
            "materials_accepted": ["Battery", "Motor", "Cable"],
            "auth_number": "MH-CPCB-2024-0089",
            "auth_status": "Active",
            "offered_rates": {"Battery": 40, "Motor": 48, "Cable": 80},
            "pickup_available": False,
            "service_radius_km": 15,
            "verified_by_admin": True
        },
        {
            "name": "Nagpur Metal Recyclers",
            "facility_address": "Hingna MIDC, Nagpur",
            "latitude": 21.1042,
            "longitude": 78.9911,
            "materials_accepted": ["PCB", "Cable", "Battery", "CRT", "LCD", "Motor", "Plastic", "Mixed"],
            "auth_number": "MH-CPCB-2024-0112",
            "auth_status": "Active",
            "offered_rates": {"PCB": 205, "Cable": 82, "Battery": 42, "CRT": 12, "LCD": 28, "Motor": 45, "Plastic": 18, "Mixed": 20},
            "pickup_available": True,
            "service_radius_km": 50,
            "verified_by_admin": True
        },
        {
            "name": "Aurangabad E-Scrap",
            "facility_address": "Waluj MIDC, Aurangabad",
            "latitude": 19.8398,
            "longitude": 75.2536,
            "materials_accepted": ["PCB", "Battery", "LCD"],
            "auth_number": "MH-CPCB-2024-0150",
            "auth_status": "Active",
            "offered_rates": {"PCB": 195, "Battery": 44, "LCD": 32},
            "pickup_available": True,
            "service_radius_km": 25,
            "verified_by_admin": True
        }
    ]
    
    for r_data in SEED_RECYCLERS:
        if not db.query(Recycler).filter_by(name=r_data["name"]).first():
            db.add(Recycler(**r_data))
    
    # 2. Seed Prices
    print("Seeding prices...")
    SEED_PRICES = [
        {"material_category": "PCB", "material_sub_cat": "Mixed PCB", "location_district": "Mumbai", "buying_price": 200, "market_price_low": 180, "market_price_high": 250},
        {"material_category": "PCB", "material_sub_cat": "Mixed PCB", "location_district": "Pune", "buying_price": 185, "market_price_low": 170, "market_price_high": 240},
        {"material_category": "Cable", "material_sub_cat": "Copper cable", "location_district": "Mumbai", "buying_price": 80, "market_price_low": 70, "market_price_high": 100},
        {"material_category": "Cable", "material_sub_cat": "Copper cable", "location_district": "Pune", "buying_price": 75, "market_price_low": 65, "market_price_high": 95},
        {"material_category": "Battery", "material_sub_cat": "Lithium-ion", "location_district": "Mumbai", "buying_price": 42, "market_price_low": 35, "market_price_high": 50},
        {"material_category": "Battery", "material_sub_cat": "Lithium-ion", "location_district": "Pune", "buying_price": 40, "market_price_low": 30, "market_price_high": 48},
        {"material_category": "LCD", "material_sub_cat": "Monitor screens", "location_district": "Mumbai", "buying_price": 28, "market_price_low": 20, "market_price_high": 35},
        {"material_category": "CRT", "material_sub_cat": "Old TVs", "location_district": "Mumbai", "buying_price": 10, "market_price_low": 5, "market_price_high": 15},
        {"material_category": "Motor", "material_sub_cat": "Mixed motors", "location_district": "Mumbai", "buying_price": 48, "market_price_low": 40, "market_price_high": 60},
        {"material_category": "Plastic", "material_sub_cat": "Hard casing", "location_district": "Mumbai", "buying_price": 15, "market_price_low": 10, "market_price_high": 22},
        {"material_category": "Mixed", "material_sub_cat": "Unsorted e-waste", "location_district": "Mumbai", "buying_price": 22, "market_price_low": 15, "market_price_high": 30},
    ]
    
    # Assign the first recycler as the source for these prices
    first_recycler = db.query(Recycler).first()
    
    for p_data in SEED_PRICES:
        if not db.query(Price).filter_by(material_category=p_data["material_category"], location_district=p_data["location_district"]).first():
            db.add(Price(
                **p_data,
                date_recorded=date.today(),
                unit="kg",
                recycler_id=first_recycler.recycler_id if first_recycler else None,
                source="Platform"
            ))
            
    # 3. Seed Collector
    print("Seeding test collector...")
    if not db.query(Collector).filter_by(display_name="Test Collector").first():
        db.add(Collector(
            preferred_language="English",
            operating_district="Mumbai",
            operating_state="Maharashtra",
            registration_date=date.today(),
            total_transactions=0,
            total_earnings=0,
            display_name="Test Collector",
            phone_hash=hash_pin("9999999999")
        ))
        
    db.commit()
    print("Seeding completed successfully.")

def seed_price_history():
    """7 days of price history per category per district — needed for trend arrows on Price Board."""
    import random
    from datetime import timedelta

    db = SessionLocal()

    districts = ['Mumbai', 'Delhi', 'Bangalore']
    base_prices = {
        'PCB': 200, 'Cable': 80, 'Battery': 45, 'LCD': 30,
        'CRT': 15, 'Motor': 60, 'Plastic': 8, 'Mixed': 25
    }
    market_ranges = {
        'PCB': (180, 250), 'Cable': (70, 100), 'Battery': (35, 60),
        'LCD': (20, 45), 'CRT': (10, 25), 'Motor': (45, 80),
        'Plastic': (5, 15), 'Mixed': (18, 35)
    }

    first_recycler = db.query(Recycler).first()
    inserted = 0

    for days_ago in range(7, 0, -1):
        record_date = date.today() - timedelta(days=days_ago)
        for district in districts:
            for category, base in base_prices.items():
                # Check idempotency — skip if this date+district+category already exists
                exists = db.query(Price).filter_by(
                    material_category=category,
                    location_district=district,
                    date_recorded=record_date
                ).first()
                if exists:
                    continue

                variation = random.uniform(0.93, 1.07)
                buying = round(base * variation, 2)
                low, high = market_ranges[category]
                db.add(Price(
                    price_id=uuid.uuid4(),
                    material_category=category,
                    material_sub_cat=f"Mixed {category}",
                    location_district=district,
                    date_recorded=record_date,
                    buying_price=buying,
                    market_price_low=low,
                    market_price_high=high,
                    unit='kg',
                    source='Manual',
                    recycler_id=first_recycler.recycler_id if first_recycler else None,
                ))
                inserted += 1

    db.commit()
    print(f"Price history seeded — {inserted} rows added (7 days × 8 categories × 3 districts = 168 target)")


if __name__ == "__main__":
    seed()
    seed_price_history()
