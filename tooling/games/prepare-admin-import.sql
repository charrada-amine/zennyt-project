-- Run in the SAME transaction as the legacy games.admin_* data dump.
-- Only replace the just-created, unedited Flyway admin seeds. Never use on an
-- actively administered database. Mobile users/sessions/results are untouched.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM games.admin_questions)
       OR EXISTS (SELECT 1 FROM games.admin_assets)
       OR EXISTS (SELECT 1 FROM games.admin_audit_log)
       OR (SELECT count(*) FROM games.admin_configurations) <> 16
       OR (SELECT count(*) FROM games.admin_banks) <> 2
       OR EXISTS (SELECT 1 FROM games.admin_configurations
           WHERE created_by <> '00000000-0000-0000-0000-000000000000'::uuid)
       OR EXISTS (SELECT 1 FROM games.admin_banks
           WHERE created_by <> '00000000-0000-0000-0000-000000000000'::uuid) THEN
        RAISE EXCEPTION 'Admin data already exists; refusing to replace it';
    END IF;
END $$;
DELETE FROM games.admin_bank_items;
DELETE FROM games.admin_banks;
DELETE FROM games.admin_configurations;
