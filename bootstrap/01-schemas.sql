\connect mktdata_collector;

--===============
-- CREATE SCHEMAS
--===============

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'RAW') THEN
        EXECUTE 'CREATE SCHEMA RAW';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'CLEANED') THEN
        EXECUTE 'CREATE SCHEMA CLEANED';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'CURATED') THEN
        EXECUTE 'CREATE SCHEMA CURATED';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'SANDBOX') THEN
        EXECUTE 'CREATE SCHEMA SANDBOX';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'SANDBOX') THEN
        EXECUTE 'CREATE SCHEMA APPLICATION';
    END IF;
END $$;


-- ===================
-- ADD SCHEMA COMMENTS
-- ===================

COMMENT ON SCHEMA raw IS 'Schema containing raw data tables before transformation';
COMMENT ON SCHEMA cleaned IS 'Schema containing cleaned data tables';
COMMENT ON SCHEMA curated IS 'Schema containing curated data tables';
COMMENT ON SCHEMA sandbox IS 'Schema containing sandbox data tables';
COMMENT ON SCHEMA application IS 'Schema containing application data tables';
