from app.database import get_supabase
sb = get_supabase()
res = sb.table('users').select('*').limit(50).execute()
for u in res.data:
    print(f"Email: {u.get('email')}, Role: {u.get('user_type')}")
