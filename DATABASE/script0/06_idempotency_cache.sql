-- Table: idempotency_cache
-- Purpose: Enforces 24-hour request deduplication on state-mutating HTTP POST/PUT endpoints.

CREATE TABLE IF NOT EXISTS public.idempotency_cache (
    key character varying(255) PRIMARY KEY,
    data json NOT NULL,
    status integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL
);

CREATE INDEX IF NOT EXISTS ix_idempotency_cache_expires_at ON public.idempotency_cache USING btree (expires_at);
