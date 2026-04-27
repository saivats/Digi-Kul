import requests

res = requests.post("http://localhost:8000/api/auth/login", json={"email": "teacher@digikul.in", "password": "password123", "user_type": "teacher"})
print(f"Login status: {res.status_code}")
if res.status_code == 200:
    token = res.json()["access_token"]
    res2 = requests.get("http://localhost:8000/api/cohorts", headers={"Authorization": f"Bearer {token}"})
    print(f"Cohorts status: {res2.status_code}")
    print(f"Cohorts body: {res2.text}")
