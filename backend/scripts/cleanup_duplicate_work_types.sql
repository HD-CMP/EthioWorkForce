-- Remove duplicate "Daily Laborer" work type created by init_db.py
-- Keep the one from seed_master_data.py (LABOR-DAY) and remove the old one (DL-001)

-- First, check which workers are using the old work type
SELECT w.id, w.employee_id, w.full_name, wt.code, wt.name
FROM workers w
JOIN work_types wt ON w.work_type_id = wt.id
WHERE wt.code IN ('DL-001', 'ENG-001');

-- Update workers to use the new work type codes
-- Daily Laborer: DL-001 → LABOR-DAY
UPDATE workers 
SET work_type_id = (SELECT id FROM work_types WHERE code = 'LABOR-DAY')
WHERE work_type_id = (SELECT id FROM work_types WHERE code = 'DL-001');

-- Site Engineer: ENG-001 → ENG-SITE
UPDATE workers 
SET work_type_id = (SELECT id FROM work_types WHERE code = 'ENG-SITE')
WHERE work_type_id = (SELECT id FROM work_types WHERE code = 'ENG-001');

-- Delete old duplicate work types
DELETE FROM work_types WHERE code IN ('DL-001', 'ENG-001');

-- Verify cleanup
SELECT id, name, code FROM work_types ORDER BY name;
