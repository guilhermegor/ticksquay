\set ON_ERROR_STOP on

-- Create extension if not exists (must be done in postgres database)
\c postgres
CREATE EXTENSION IF NOT EXISTS dblink;

-- Drop database if it exists with wrong configuration
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_database WHERE datname = 'mktdata_collector') THEN
        -- Simple check for ICU provider (can't fully check collation without connecting)
        IF EXISTS (
            SELECT 1 FROM pg_database
            WHERE datname = 'mktdata_collector'
            AND datlocprovider != 'i'
        ) THEN
            RAISE NOTICE 'Dropping existing database with incorrect configuration...';
            PERFORM dblink_exec('dbname=postgres', 'DROP DATABASE mktdata_collector');
        ELSE
            RAISE NOTICE 'Database exists with correct configuration, skipping creation';
            RETURN;
        END IF;
    END IF;
END $$;

-- Create the database with desired configuration
CREATE DATABASE mktdata_collector
WITH
  TEMPLATE = template0
  ENCODING = 'UTF8'
  LOCALE_PROVIDER = icu
  ICU_LOCALE = 'pt-BR';

-- Connect to the new database
\c mktdata_collector

-- Create schemas
CREATE SCHEMA IF NOT EXISTS raw;
COMMENT ON SCHEMA raw IS 'Schema containing raw data tables before transformation';

CREATE SCHEMA IF NOT EXISTS cleaned;
COMMENT ON SCHEMA cleaned IS 'Schema containing cleaned data tables';

CREATE SCHEMA IF NOT EXISTS curated;
COMMENT ON SCHEMA curated IS 'Schema containing curated data tables';

CREATE SCHEMA IF NOT EXISTS sandbox;
COMMENT ON SCHEMA sandbox IS 'Schema containing sandbox data tables';

CREATE SCHEMA IF NOT EXISTS application;
COMMENT ON SCHEMA application IS 'Schema containing application data tables';

-- Verify schemas were created
\dn+
