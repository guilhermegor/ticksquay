\connect mktdata_collector;

-- COMPANIES
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
                COMPANY_SHARE_CAPITAL NUMERIC(15, 4) NOT NULL,
                COMPANY_SIZE NUMERIC(10, 0) NOT NULL,
                RESP_FEDERAL_ENTITY VARCHAR(30) NOT NULL,
                URL VARCHAR(255),
                REF_DATE DATE NOT NULL DEFAULT CURRENT_DATE,
                LOG_TIMESTAMP TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_schema = 'raw'
                   AND constraint_name = 'pk_br_irs_companies_cnpj') THEN
        EXECUTE '
            ALTER TABLE raw.br_irs_companies
            ADD CONSTRAINT pk_br_irs_companies_cnpj PRIMARY KEY (CNPJ);
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes
                   WHERE schemaname = 'raw'
                   AND indexname = 'idx_br_irs_companies_cnpj') THEN
        EXECUTE '
            CREATE INDEX idx_br_irs_companies_cnpj ON raw.br_irs_companies (CNPJ);
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_schema = 'raw'
                   AND constraint_name = 'uq_br_irs_companies_unique_combination') THEN
        EXECUTE '
            ALTER TABLE raw.br_irs_companies
            ADD CONSTRAINT uq_br_irs_companies_unique_combination
            UNIQUE (CNPJ, COMPANY_NAME, LEGAL_FORM);
        ';
    END IF;
END $$;

-- BUSINESSES
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables
                   WHERE table_schema = 'raw' AND table_name = 'br_irs_businesses') THEN
        EXECUTE '
            CREATE TABLE raw.br_irs_businesses (
                EIN_BASIC VARCHAR(14) NOT NULL,
                EIN_ORDER VARCHAR(14) NOT NULL,
                EIN_VD VARCHAR(14) NOT NULL,
                ID_HEADQUARTERS_BRANCH NUMERIC(8, 0) NOT NULL,
                COMPANY_NAME VARCHAR(100) NOT NULL,
                ID_REGISTRATION_STATUS VARCHAR(30) NOT NULL,
                DT_REGISTRATION_STATUS DATE NOT NULL,
                ID_REASON_REGISTRATION_STATUS NUMERIC(8, 0) NOT NULL,
                CITY_FOREIGN_COUNTRY VARCHAR(100) NOT NULL,
                COUNTRY VARCHAR(30) NOT NULL,
                DT_INCEPTION DATE NOT NULL,
                CNAE_MAIN VARCHAR(10) NOT NULL,
                CNAE_SECOND VARCHAR(10) NOT NULL,
                TYPE_PUBLIC_PLACE VARCHAR(100) NOT NULL,
                DESC_PUBLIC_PLACE VARCHAR(100) NOT NULL,
                NUMBER NUMERIC(10, 0) NOT NULL,
                ADDRESS_COMPLEMENT VARCHAR(100) NOT NULL,
                NEIGHBORHOOD VARCHAR(100) NOT NULL,
                ZIP_CODE VARCHAR(10) NOT NULL,
                STATE VARCHAR(30) NOT NULL,
                CITY VARCHAR(100) NOT NULL,
                AREA_CODE_1 NUMERIC(3, 0) NOT NULL,
                TELEPHONE_1 NUMERIC(10, 0) NOT NULL,
                AREA_CODE_2 NUMERIC(3, 0) NOT NULL,
                TELEPHONE_2 NUMERIC(10, 0) NOT NULL,
                AREA_CODE_FAX NUMERIC(3, 0) NOT NULL,
                FAX NUMERIC(10, 0) NOT NULL,
                ELECTRONIC_MAILING VARCHAR(100) NOT NULL,
                SPECIAL_SIT VARCHAR(30) NOT NULL,
                DT_SPECIAL_SIT DATE NOT NULL,
                URL VARCHAR(255),
                REF_DATE DATE NOT NULL DEFAULT CURRENT_DATE,
                LOG_TIMESTAMP TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_schema = 'raw'
                   AND constraint_name = 'pk_br_irs_businesses_ein') THEN
        EXECUTE '
            ALTER TABLE raw.br_irs_businesses
            ADD CONSTRAINT pk_br_irs_businesses_ein
            PRIMARY KEY (EIN_BASIC, EIN_ORDER, EIN_VD);
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes
                   WHERE schemaname = 'raw' AND indexname = 'idx_br_irs_businesses_ein') THEN
        EXECUTE '
            CREATE INDEX idx_br_irs_businesses_ein
            ON raw.br_irs_businesses (EIN_BASIC, EIN_ORDER, EIN_VD);
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_schema = 'raw'
                   AND constraint_name = 'uq_br_irs_businesses_unique_combination') THEN
        EXECUTE '
            ALTER TABLE raw.br_irs_businesses
            ADD CONSTRAINT uq_br_irs_businesses_unique_combination
            UNIQUE (EIN_BASIC, EIN_ORDER, EIN_VD, COMPANY_NAME);
        ';
    END IF;
END $$;

-- SIMPLIFIED TAXATION SYSTEM
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables
                   WHERE table_schema = 'raw' AND table_name = 'br_irs_simp_tax_sys') THEN
        EXECUTE '
            CREATE TABLE raw.br_irs_simp_tax_sys (
                CNPJ VARCHAR(14) NOT NULL,
                BL_SIMPL_TX VARCHAR(3) NOT NULL,
                DT_BEG_SIMPL_TX DATE NOT NULL,
                DT_END_SIMPL_TX DATE NOT NULL,
                BL_MEI_TX VARCHAR(3) NOT NULL,
                DT_BEG_MEI_TX DATE NOT NULL,
                DT_END_MEI_TX DATE NOT NULL,
                URL VARCHAR(255),
                REF_DATE DATE NOT NULL DEFAULT CURRENT_DATE,
                LOG_TIMESTAMP TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_schema = 'raw' AND constraint_name = 'pk_br_irs_simp_tax_sys_cnpj') THEN
        EXECUTE '
            ALTER TABLE raw.br_irs_simp_tax_sys
            ADD CONSTRAINT pk_br_irs_simp_tax_sys_cnpj PRIMARY KEY (CNPJ);
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes
                   WHERE schemaname = 'raw' AND indexname = 'idx_br_irs_simp_tax_sys_cnpj') THEN
        EXECUTE '
            CREATE INDEX idx_br_irs_simp_tax_sys_cnpj ON raw.br_irs_simp_tax_sys (CNPJ);
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_schema = 'raw'
                   AND constraint_name = 'uq_br_irs_simp_tax_sys_unique') THEN
        EXECUTE '
            ALTER TABLE raw.br_irs_simp_tax_sys
            ADD CONSTRAINT uq_br_irs_simp_tax_sys_unique
            UNIQUE (CNPJ, BL_SIMPL_TX, BL_MEI_TX);
        ';
    END IF;
END $$;

-- SHAREHOLDERS
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables
                   WHERE table_schema = 'raw' AND table_name = 'br_irs_shareholders') THEN
        EXECUTE '
            CREATE TABLE raw.br_irs_shareholders (
                EIN_COMPANY VARCHAR(14) NOT NULL,
                ID_TYPE_PERSON NUMERIC(10, 0) NOT NULL,
                NAME VARCHAR(100) NOT NULL,
                DOC_SHAREHOLDER VARCHAR(14) NOT NULL,
                SHAREHOLDER_EDUCATION VARCHAR(100) NOT NULL,
                DT_BEG_SHAREHOLDER DATE NOT NULL,
                COUNTRY VARCHAR(30) NOT NULL,
                LEGAL_REPRESENTATIVE VARCHAR(100) NOT NULL,
                REPRESENTATIVE_NAME VARCHAR(100) NOT NULL,
                REPRESENTATIVE_EDUCATION VARCHAR(100) NOT NULL,
                AGE_RANGE VARCHAR(30) NOT NULL,
                URL VARCHAR(255),
                REF_DATE DATE NOT NULL DEFAULT CURRENT_DATE,
                LOG_TIMESTAMP TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_schema = 'raw' AND constraint_name = 'pk_br_irs_shareholders') THEN
        EXECUTE '
            ALTER TABLE raw.br_irs_shareholders
            ADD CONSTRAINT pk_br_irs_shareholders
            PRIMARY KEY (EIN_COMPANY, DOC_SHAREHOLDER);
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes
                   WHERE schemaname = 'raw' AND indexname = 'idx_br_irs_shareholders_ein') THEN
        EXECUTE '
            CREATE INDEX idx_br_irs_shareholders_ein ON raw.br_irs_shareholders (EIN_COMPANY);
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_schema = 'raw'
                   AND constraint_name = 'uq_br_irs_shareholders_unique') THEN
        EXECUTE '
            ALTER TABLE raw.br_irs_shareholders
            ADD CONSTRAINT uq_br_irs_shareholders_unique
            UNIQUE (EIN_COMPANY, DOC_SHAREHOLDER, NAME);
        ';
    END IF;
END $$;

-- COUNTRIES
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables
                   WHERE table_schema = 'raw' AND table_name = 'br_irs_countries') THEN
        EXECUTE '
            CREATE TABLE raw.br_irs_countries (
                CODE VARCHAR(3) NOT NULL,
                NAME VARCHAR(100) NOT NULL,
                URL VARCHAR(255),
                REF_DATE DATE NOT NULL DEFAULT CURRENT_DATE,
                LOG_TIMESTAMP TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_schema = 'raw' AND constraint_name = 'pk_br_irs_countries_code') THEN
        EXECUTE '
            ALTER TABLE raw.br_irs_countries
            ADD CONSTRAINT pk_br_irs_countries_code PRIMARY KEY (CODE);
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes
                   WHERE schemaname = 'raw' AND indexname = 'idx_br_irs_countries_code') THEN
        EXECUTE '
            CREATE INDEX idx_br_irs_countries_code ON raw.br_irs_countries (CODE);
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_schema = 'raw'
                   AND constraint_name = 'uq_br_irs_countries_name') THEN
        EXECUTE '
            ALTER TABLE raw.br_irs_countries
            ADD CONSTRAINT uq_br_irs_countries_name
            UNIQUE (CODE, NAME);
        ';
    END IF;
END $$;

-- CITIES
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables
                   WHERE table_schema = 'raw' AND table_name = 'br_irs_cities') THEN
        EXECUTE '
            CREATE TABLE raw.br_irs_cities (
                CODE VARCHAR(7) NOT NULL,
                NAME VARCHAR(100) NOT NULL,
                URL VARCHAR(255),
                REF_DATE DATE NOT NULL DEFAULT CURRENT_DATE,
                LOG_TIMESTAMP TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_schema = 'raw' AND constraint_name = 'pk_br_irs_cities_code') THEN
        EXECUTE '
            ALTER TABLE raw.br_irs_cities
            ADD CONSTRAINT pk_br_irs_cities_code PRIMARY KEY (CODE);
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes
                   WHERE schemaname = 'raw' AND indexname = 'idx_br_irs_cities_code') THEN
        EXECUTE '
            CREATE INDEX idx_br_irs_cities_code ON raw.br_irs_cities (CODE, NAME);
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_schema = 'raw'
                   AND constraint_name = 'uq_br_irs_cities_name') THEN
        EXECUTE '
            ALTER TABLE raw.br_irs_cities
            ADD CONSTRAINT uq_br_irs_cities_name
            UNIQUE (NAME);
        ';
    END IF;
END $$;

-- SHAREHOLDERS EDUCATION
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables
                   WHERE table_schema = 'raw' AND table_name = 'br_irs_shareholders_education') THEN
        EXECUTE '
            CREATE TABLE raw.br_irs_shareholders_education (
                CODE VARCHAR(2) NOT NULL,
                DESCRIPTION VARCHAR(100) NOT NULL,
                REF_DATE DATE NOT NULL DEFAULT CURRENT_DATE,
                LOG_TIMESTAMP TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_schema = 'raw' AND constraint_name = 'pk_br_irs_shareholders_education_code') THEN
        EXECUTE '
            ALTER TABLE raw.br_irs_shareholders_education
            ADD CONSTRAINT pk_br_irs_shareholders_education_code PRIMARY KEY (CODE);
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes
                   WHERE schemaname = 'raw' AND indexname = 'idx_br_irs_shareholders_education_code') THEN
        EXECUTE '
            CREATE INDEX idx_br_irs_shareholders_education_code ON raw.br_irs_shareholders_education (CODE);
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_schema = 'raw'
                   AND constraint_name = 'uq_br_irs_shareholders_education_desc') THEN
        EXECUTE '
            ALTER TABLE raw.br_irs_shareholders_education
            ADD CONSTRAINT uq_br_irs_shareholders_education_desc
            UNIQUE (DESCRIPTION);
        ';
    END IF;
END $$;

-- LEGAL FORM
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables
                   WHERE table_schema = 'raw' AND table_name = 'br_irs_legal_form') THEN
        EXECUTE '
            CREATE TABLE raw.br_irs_legal_form (
                CODE VARCHAR(4) NOT NULL,
                DESCRIPTION VARCHAR(100) NOT NULL,
                REF_DATE DATE NOT NULL DEFAULT CURRENT_DATE,
                LOG_TIMESTAMP TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_schema = 'raw' AND constraint_name = 'pk_br_irs_legal_form_code') THEN
        EXECUTE '
            ALTER TABLE raw.br_irs_legal_form
            ADD CONSTRAINT pk_br_irs_legal_form_code PRIMARY KEY (CODE);
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes
                   WHERE schemaname = 'raw' AND indexname = 'idx_br_irs_legal_form_code') THEN
        EXECUTE '
            CREATE INDEX idx_br_irs_legal_form_code ON raw.br_irs_legal_form (CODE);
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_schema = 'raw'
                   AND constraint_name = 'uq_br_irs_legal_form_desc') THEN
        EXECUTE '
            ALTER TABLE raw.br_irs_legal_form
            ADD CONSTRAINT uq_br_irs_legal_form_desc
            UNIQUE (DESCRIPTION);
        ';
    END IF;
END $$;

-- NATIONAL CLASSIFICATION OF ECONOMIC ACTIVITY (CNAES)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables
                   WHERE table_schema = 'raw' AND table_name = 'br_irs_rfb_cnaes') THEN
        EXECUTE '
            CREATE TABLE raw.br_irs_rfb_cnaes (
                CODE VARCHAR(7) NOT NULL,
                DESCRIPTION VARCHAR(200) NOT NULL,
                REF_DATE DATE NOT NULL DEFAULT CURRENT_DATE,
                LOG_TIMESTAMP TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_schema = 'raw' AND constraint_name = 'pk_br_irs_rfb_cnaes_code') THEN
        EXECUTE '
            ALTER TABLE raw.br_irs_rfb_cnaes
            ADD CONSTRAINT pk_br_irs_rfb_cnaes_code PRIMARY KEY (CODE);
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes
                   WHERE schemaname = 'raw' AND indexname = 'idx_br_irs_rfb_cnaes_code') THEN
        EXECUTE '
            CREATE INDEX idx_br_irs_rfb_cnaes_code ON raw.br_irs_rfb_cnaes (CODE);
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_schema = 'raw'
                   AND constraint_name = 'uq_br_irs_rfb_cnaes_desc') THEN
        EXECUTE '
            ALTER TABLE raw.br_irs_rfb_cnaes
            ADD CONSTRAINT uq_br_irs_rfb_cnaes_desc
            UNIQUE (DESCRIPTION);
        ';
    END IF;
END $$;

-- REGISTRATION STATUS
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables
                   WHERE table_schema = 'raw' AND table_name = 'br_irs_registration_status') THEN
        EXECUTE '
            CREATE TABLE raw.br_irs_registration_status (
                CODE VARCHAR(2) NOT NULL,
                REASON_REG_STATUS VARCHAR(100) NOT NULL,
                REF_DATE DATE NOT NULL DEFAULT CURRENT_DATE,
                LOG_TIMESTAMP TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_schema = 'raw' AND constraint_name = 'pk_br_irs_registration_status_code') THEN
        EXECUTE '
            ALTER TABLE raw.br_irs_registration_status
            ADD CONSTRAINT pk_br_irs_registration_status_code PRIMARY KEY (CODE);
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes
                   WHERE schemaname = 'raw' AND indexname = 'idx_br_irs_registration_status_code') THEN
        EXECUTE '
            CREATE INDEX idx_br_irs_registration_status_code ON raw.br_irs_registration_status (CODE);
        ';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_schema = 'raw'
                   AND constraint_name = 'uq_br_irs_registration_status_reason') THEN
        EXECUTE '
            ALTER TABLE raw.br_irs_registration_status
            ADD CONSTRAINT uq_br_irs_registration_status_reason
            UNIQUE (REASON_REG_STATUS);
        ';
    END IF;
END $$;
