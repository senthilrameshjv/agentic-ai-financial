-- Table: public.officer_transcripts

-- DROP TABLE IF EXISTS public.officer_transcripts;

CREATE TABLE IF NOT EXISTS public.officer_transcripts
(
    transcript_id bigint NOT NULL DEFAULT nextval('officer_transcripts_transcript_id_seq'::regclass),
    loan_officer_id bigint NOT NULL,
    customer_id bigint NOT NULL,
    transcript_text text COLLATE pg_catalog."default" NOT NULL,
    meeting_date date NOT NULL,
    meeting_type character varying(30) COLLATE pg_catalog."default" NOT NULL,
    embedding vector(1536),
    CONSTRAINT officer_transcripts_pkey PRIMARY KEY (transcript_id),
    CONSTRAINT officer_transcripts_meeting_type_check CHECK (meeting_type::text = ANY (ARRAY['annual_review'::character varying, 'loan_application'::character varying, 'modification'::character varying, 'branch_visit'::character varying, 'phone'::character varying]::text[]))
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.officer_transcripts
    OWNER to postgres;
-- Index: idx_transcripts_customer

-- DROP INDEX IF EXISTS public.idx_transcripts_customer;

CREATE INDEX IF NOT EXISTS idx_transcripts_customer
    ON public.officer_transcripts USING btree
    (customer_id ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;
-- Index: idx_transcripts_date

-- DROP INDEX IF EXISTS public.idx_transcripts_date;

CREATE INDEX IF NOT EXISTS idx_transcripts_date
    ON public.officer_transcripts USING btree
    (meeting_date ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;
-- Index: idx_transcripts_officer

-- DROP INDEX IF EXISTS public.idx_transcripts_officer;

CREATE INDEX IF NOT EXISTS idx_transcripts_officer
    ON public.officer_transcripts USING btree
    (loan_officer_id ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;