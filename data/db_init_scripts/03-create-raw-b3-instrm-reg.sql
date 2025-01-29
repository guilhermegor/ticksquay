-- ensure connection to mktdata_collector database
\connect mktdata_collector;

-- create the table B3_INSTRM_REG if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'RAW' AND table_name = 'B3_INSTRM_REG') THEN
        EXECUTE '
            CREATE TABLE RAW.B3_INSTRM_REG (
                RPT_DT DATE NOT NULL,
                TCKR_SYMB VARCHAR(10) NOT NULL,
                ASST VARCHAR(10),
                ASST_DESC VARCHAR(50),
                SGMT_NM VARCHAR(30),
                MKT_NM VARCHAR(30),
                SCTY_CTGY_NM VARCHAR(30),
                XPRTN_DT DATE,
                XPRTN_CD VARCHAR(10),
                TRADG_START_DT DATE,
                TRADG_END_DT DATE,
                BASE_CD VARCHAR(10),
                CONVS_CRIT_NM VARCHAR(50),
                MTRTY_DT_TRGT_PT INTEGER,
                REQRD_CONVS_IND VARCHAR(2),
                ISIN VARCHAR(20),
                CFICD VARCHAR(10),
                DLVRY_NTCE_START_DT DATE,
                DLVRY_NTCE_END_DT DATE,
                OPTN_TP VARCHAR(10),
                CTRCT_MLTPLR INTEGER,
                ASST_QTN_QTY INTEGER,
                ALLCN_RND_LOT INTEGER,
                TRADG_CCY VARCHAR(3),
                DLVRY_TP_NM VARCHAR(30),
                WDRWL_DAYS INTEGER,
                WRKG_DAYS INTEGER,
                CLNR_DAYS INTEGER,
                RLVR_BASE_PRIC_NM VARCHAR(30),
                OPNG_FUTR_POS_DAY INTEGER,
                SD_TP_CD1 VARCHAR(10),
                UNDRLYG_TCKR_SYMB1 VARCHAR(10),
                SD_TP_CD2 VARCHAR(10),
                UNDRLYG_TCKR_SYMB2 VARCHAR(10),
                PURE_GOLD_WGHT DECIMAL(15, 4),
                EXRC_PRIC DECIMAL(15, 4),
                OPTN_STYLE VARCHAR(10),
                VAL_TP_NM VARCHAR(30),
                PRM_UPFRNT_IND VARCHAR(2),
                OPNG_POS_LMT_DT DATE,
                DSTRBTN_ID VARCHAR(10),
                PRIC_FCTR DECIMAL(10, 4),
                DAYS_TO_STTLM INTEGER,
                SRS_TP_NM VARCHAR(30),
                PRTCN_FLG VARCHAR(2),
                AUTOMTC_EXRC_IND VARCHAR(2),
                SPCFTN_CD VARCHAR(10),
                CRPN_NM VARCHAR(50),
                CORP_ACTN_START_DT DATE,
                CTDY_TRTMT_TP_NM VARCHAR(30),
                MKT_CPTLSTN DECIMAL(20, 4),
                CORP_GOVN_LVL_NM VARCHAR(30),
                URL VARCHAR(255),
                LAST_UPDATE TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                LOG_TIMESTAMP TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
        ';
    END IF;
END $$;

-- add primary key constraint if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_schema = 'RAW' AND constraint_name = 'pk_tckrsymb') THEN
        ALTER TABLE RAW.B3_INSTRM_REG
        ADD CONSTRAINT pk_tckrsymb PRIMARY KEY (TCKR_SYMB);
    END IF;
END $$;

-- create index on TCKR_SYMB if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes 
                   WHERE schemaname = 'RAW' AND indexname = 'idx_tckrsymb') THEN
        CREATE INDEX idx_tckrsymb ON RAW.B3_INSTRM_REG (TCKR_SYMB);
    END IF;
END $$;