import urllib.request
import urllib.parse
import json

data = urllib.parse.urlencode({'username': 'admin@example.com', 'password': 'password'}).encode()
req = urllib.request.Request('http://localhost:8000/api/v1/auth/login', data=data)
res = urllib.request.urlopen(req)
token = json.loads(res.read())['access_token']

req2 = urllib.request.Request('http://localhost:8000/api/v1/attendance/?limit=5000&date_from=2026-04-28&date_to=2026-10-25')
req2.add_header('Authorization', 'Bearer ' + token)
res2 = urllib.request.urlopen(req2)
attendances = json.loads(res2.read())
found = False
for a in attendances:
    if a['worker_id'] == 5:
        print(f"ID: {a['id']}, Worker: {a['worker_id']}, Date: {a['attendance_date']}, Verified: {a['is_verified']}")
        found = True
if not found:
    print('Worker 5 not found in API response!')
