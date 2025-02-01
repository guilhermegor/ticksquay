DO $$ 
DECLARE
    db_name TEXT;
BEGIN
    -- List of databases to create
    FOR db_name IN VALUES ('mktdata_collector'), ('registries_collector') LOOP
        -- Check if the database exists, and create it if necessary
        IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_database WHERE datname = db_name) THEN
            EXECUTE format('CREATE DATABASE %I 
                            WITH 
                                TEMPLATE = template0
                                ENCODING = ''UTF8''
                                LOCALE_PROVIDER = icu
                                ICU_LOCALE = ''pt-BR''', db_name);
            RAISE NOTICE 'Database % created.', db_name;
        ELSE
            RAISE NOTICE 'Database % already exists.', db_name;
        END IF;
    END LOOP;
END $$;

-- Listing available databases
DO $$ 
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT datname FROM pg_database WHERE datistemplate = false
    LOOP
        RAISE NOTICE 'Database: %', rec.datname;
    END LOOP;
END $$;

-- Switch to each database (if needed)
DO $$ 
DECLARE
    db_name TEXT;
BEGIN
    FOR db_name IN VALUES ('mktdata_collector'), ('registries_collector') LOOP
        EXECUTE format('\connect %I', db_name);
        RAISE NOTICE 'Switched to database: %', db_name;
    END LOOP;
END $$;