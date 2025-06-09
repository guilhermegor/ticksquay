-- ============
-- CREATE ROLES
-- ============

-- admin role with full permissions
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_admin') THEN
        CREATE ROLE role_admin WITH NOLOGIN;
        COMMENT ON ROLE role_admin IS 'Administrator role with full permissions on mktdata_collector database';
    END IF;
END $$;

-- developer role with read/write permissions
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_developer') THEN
        CREATE ROLE role_developer WITH NOLOGIN;
        COMMENT ON ROLE role_developer IS 'Developer role with read/write permissions on all schemas except RAW';
    END IF;
END $$;

-- read-only role for application schema
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_reader') THEN
        CREATE ROLE role_reader WITH NOLOGIN;
        COMMENT ON ROLE role_reader IS 'Read-only role for application schema';
    END IF;
END $$;

-- etl role for data loading
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_etl') THEN
        CREATE ROLE role_etl WITH NOLOGIN;
        COMMENT ON ROLE role_etl IS 'ETL role with write permissions on RAW schema';
    END IF;
END $$;

-- ========================
-- GRANT SCHEMA PERMISSIONS
-- ========================

-- grant permissions to admin role
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA raw, cleaned, curated, sandbox, application TO role_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA raw, cleaned, curated, sandbox, application TO role_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA raw, cleaned, curated, sandbox, application TO role_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA raw, cleaned, curated, sandbox, application GRANT ALL PRIVILEGES ON TABLES TO role_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA raw, cleaned, curated, sandbox, application GRANT ALL PRIVILEGES ON SEQUENCES TO role_admin;

-- grant permissions to developer role
GRANT USAGE ON SCHEMA cleaned, curated, sandbox, application TO role_developer;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA cleaned, curated, sandbox, application TO role_developer;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA cleaned, curated, sandbox, application TO role_developer;
ALTER DEFAULT PRIVILEGES IN SCHEMA cleaned, curated, sandbox, application GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO role_developer;
ALTER DEFAULT PRIVILEGES IN SCHEMA cleaned, curated, sandbox, application GRANT USAGE ON SEQUENCES TO role_developer;

-- grant permissions to read-only role (specific to application schema)
GRANT USAGE ON SCHEMA application TO role_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA application TO role_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA application GRANT SELECT ON TABLES TO role_reader;

-- grant permissions to etl role
GRANT USAGE ON SCHEMA raw TO role_etl;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA raw TO role_etl;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA raw TO role_etl;
ALTER DEFAULT PRIVILEGES IN SCHEMA raw GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO role_etl;
ALTER DEFAULT PRIVILEGES IN SCHEMA raw GRANT USAGE ON SEQUENCES TO role_etl;

-- =================
-- ADD ROLE COMMENTS
-- =================

COMMENT ON ROLE role_admin IS 'Administrator role with full permissions on mktdata_collector database';
COMMENT ON ROLE role_developer IS 'Developer role with read/write permissions on all schemas except RAW';
COMMENT ON ROLE role_reader IS 'Read-only role for application schema';
COMMENT ON ROLE role_etl IS 'ETL role with write permissions on RAW schema';
