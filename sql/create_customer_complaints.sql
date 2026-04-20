-- Table: public.customer_complaints

-- DROP TABLE IF EXISTS public.customer_complaints;

CREATE TABLE IF NOT EXISTS public.customer_complaints
(
    complaint_id bigint NOT NULL DEFAULT nextval('customer_complaints_complaint_id_seq'::regclass),
    customer_id bigint NOT NULL,
    complaint_text text COLLATE pg_catalog."default" NOT NULL,
    channel character varying(20) COLLATE pg_catalog."default" NOT NULL,
    complaint_date date NOT NULL,
    resolved boolean NOT NULL DEFAULT true,
    embedding vector(1536),
    CONSTRAINT customer_complaints_pkey PRIMARY KEY (complaint_id),
    CONSTRAINT customer_complaints_channel_check CHECK (channel::text = ANY (ARRAY['call'::character varying, 'email'::character varying, 'ticket'::character varying, 'chat'::character varying, 'branch'::character varying]::text[]))
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.customer_complaints
    OWNER to postgres;
-- Index: idx_complaints_customer

-- DROP INDEX IF EXISTS public.idx_complaints_customer;

CREATE INDEX IF NOT EXISTS idx_complaints_customer
    ON public.customer_complaints USING btree
    (customer_id ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;
-- Index: idx_complaints_date

-- DROP INDEX IF EXISTS public.idx_complaints_date;

CREATE INDEX IF NOT EXISTS idx_complaints_date
    ON public.customer_complaints USING btree
    (complaint_date ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;