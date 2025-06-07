\connect mktdata_collector;

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
