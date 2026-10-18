import requests

# Test the users endpoint
response = requests.get('http://172.26.151.36:8000/api/v1/users')
print(f'Status: {response.status_code}')

if response.status_code == 200:
    users = response.json()
    print(f'\nFound {len(users)} users')
    for user in users:
        print(f"\nUser: {user['username']} (Role: {user['role']})")
        if 'site_assignments' in user:
            print(f"  Site assignments: {user['site_assignments']}")
        else:
            print("  No site_assignments field!")
else:
    print(f'Error: {response.text}')
