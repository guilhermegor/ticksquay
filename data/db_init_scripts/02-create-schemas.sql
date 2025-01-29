-- ensure connection to mktdata_collector database
\connect mktdata_collector;

-- create the RAW schema if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'RAW') THEN
        EXECUTE 'CREATE SCHEMA RAW';
    END IF;
END $$;

-- create the CLEANED schema if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'CLEANED') THEN
        EXECUTE 'CREATE SCHEMA CLEANED';
    END IF;
END $$;

-- create the CURATED schema if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'CURATED') THEN
        EXECUTE 'CREATE SCHEMA CURATED';
    END IF;
END $$;
