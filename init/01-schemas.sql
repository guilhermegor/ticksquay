\connect mktdata_collector;


--===============
-- CREATE SCHEMAS
--===============

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'raw') THEN
        EXECUTE 'CREATE SCHEMA raw';
        EXECUTE 'COMMENT ON SCHEMA raw IS ''Schema containing raw data tables before transformation''';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'cleaned') THEN
        EXECUTE 'CREATE SCHEMA cleaned';
        EXECUTE 'COMMENT ON SCHEMA cleaned IS ''Schema containing cleaned data tables''';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'curated') THEN
        EXECUTE 'CREATE SCHEMA curated';
        EXECUTE 'COMMENT ON SCHEMA curated IS ''Schema containing curated data tables''';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'sandbox') THEN
        EXECUTE 'CREATE SCHEMA sandbox';
        EXECUTE 'COMMENT ON SCHEMA sandbox IS ''Schema containing sandbox data tables''';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'application') THEN
        EXECUTE 'CREATE SCHEMA application';
        EXECUTE 'COMMENT ON SCHEMA application IS ''Schema containing application data tables''';
    END IF;
END $$;
