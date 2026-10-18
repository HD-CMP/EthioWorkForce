#!/usr/bin/env python3
from app.database import get_db
from app.models import User, UserSiteAssignment, Site

db = next(get_db())

# Check users
users = db.query(User).all()
print(f"Total users in database: {len(users)}\n")
print("First 5 users:")
for u in users[:5]:
    print(f"  ID: {u.id}, Username: {u.username}, Name: {u.full_name}, Active: {u.is_active}")

# Check sites
print("\n\nSites:")
sites = db.query(Site).all()
for s in sites:
    print(f"  Site ID: {s.id}, Name: {s.name}")

# Check site assignments
print("\n\nUser Site Assignments:")
assignments = db.query(UserSiteAssignment).all()
print(f"Total assignments: {len(assignments)}")
for a in assignments[:10]:
    user = db.query(User).filter(User.id == a.user_id).first()
    site = db.query(Site).filter(Site.id == a.site_id).first()
    print(f"  User {a.user_id} ({user.username if user else 'N/A'}) -> Site {a.site_id} ({site.name if site else 'N/A'})")

# Test search query
print("\n\nTesting search for 'as':")
search_term = "%as%"
results = db.query(User).filter(
    (User.full_name.ilike(search_term)) |
    (User.username.ilike(search_term)) |
    (User.email.ilike(search_term))
).filter(User.is_active == True).all()
print(f"Found {len(results)} users matching 'as':")
for u in results:
    print(f"  {u.username} - {u.full_name} ({u.email})")

# Test search with site filter (assuming Anfoo is site_id 1)
print("\n\nTesting search for 'as' at Anfoo site:")
anfoo_site = db.query(Site).filter(Site.name == "Anfoo").first()
if anfoo_site:
    print(f"Anfoo site ID: {anfoo_site.id}")
    results_with_site = db.query(User).filter(
        (User.full_name.ilike(search_term)) |
        (User.username.ilike(search_term)) |
        (User.email.ilike(search_term))
    ).join(User.site_assignments).filter(
        UserSiteAssignment.site_id == anfoo_site.id
    ).filter(User.is_active == True).distinct().all()
    print(f"Found {len(results_with_site)} users at Anfoo matching 'as':")
    for u in results_with_site:
        print(f"  {u.username} - {u.full_name} ({u.email})")
else:
    print("Anfoo site not found!")
