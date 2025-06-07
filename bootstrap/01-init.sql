SELECT 'Creating mktdata_collector database'
WHERE NOT EXISTS (SELECT 1 FROM pg_catalog.pg_database WHERE datname = 'mktdata_collector');

CREATE DATABASE mktdata_collector
WITH
    TEMPLATE = template0
    ENCODING = 'UTF8'
    LOCALE_PROVIDER = icu
    ICU_LOCALE = 'pt-BR';

-- listing available databases
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
