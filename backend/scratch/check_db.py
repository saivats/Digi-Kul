import os
from dotenv import load_dotenv
from supabase import create_client

load_dotenv("backend/.env")

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_KEY")
sb = create_client(url, key)

print(f"Checking Supabase at {url}")

def check():
    for table in ["institution_admins", "teachers", "students"]:
        res = sb.table(table).select("email, institution_id").execute()
        print(f"Table {table}: {[(r['email'], r.get('institution_id')) for r in res.data]}")


if __name__ == "__main__":
    check()
