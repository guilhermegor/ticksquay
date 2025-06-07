\connect mktdata_collector;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables
                   WHERE table_schema = 'raw' AND table_name = 'br_irs_companies') THEN
        EXECUTE '
            CREATE TABLE raw.br_irs_companies (
                CNPJ VARCHAR(14) NOT NULL,
                COMPANY_NAME VARCHAR(100) NOT NULL,
                LEGAL_FORM VARCHAR(30) NOT NULL,
                LEGAL_RESP_QUALIF VARCHAR(30) NOT NULL,
                COMPANY_SHARE_CAPITAL DECIMAL(20, 4) NOT NULL,
                COMPANY_SIZE INTEGER NOT NULL,
                RESP_FEDERAL_ENTITY VARCHAR(30) NOT NULL,
                URL VARCHAR(255),
                REF_DATE TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                LOG_TIMESTAMP TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_schema = 'raw' AND constraint_name = 'pk_br_irs_companies_cnpj') THEN
        ALTER TABLE raw.br_irs_companies
        ADD CONSTRAINT pk_tckrsymb PRIMARY KEY (CNPJ);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes
                   WHERE schemaname = 'raw' AND indexname = 'idx_br_irs_companies_cnpj') THEN
        CREATE INDEX idx_tckrsymb ON raw.br_irs_companies (CNPJ);
    END IF;
END $$;
