from app.core.config import settings
import psycopg2

conn = psycopg2.connect(settings.DATABASE_URL)
cur = conn.cursor()

print('Recent users:')
cur.execute('SELECT id, username, role, email FROM users ORDER BY id DESC LIMIT 5')
rows = cur.fetchall()
for r in rows:
    print(f'  ID: {r[0]}, Username: {r[1]}, Role: {r[2]}, Email: {r[3]}')

print('\nUser site assignments:')
cur.execute('''
    SELECT u.id, u.username, usa.site_id, usa.is_primary
    FROM users u
    LEFT JOIN user_site_assignments usa ON u.id = usa.user_id
    ORDER BY u.id DESC
    LIMIT 10
''')
rows = cur.fetchall()
for r in rows:
    print(f'  User {r[0]} ({r[1]}): Site {r[2]}, Primary: {r[3]}')

cur.close()
conn.close()
