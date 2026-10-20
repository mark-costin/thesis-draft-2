-- Table: invites
-- Purpose: Single-use QR invite tokens and alphanumeric codes for onboarding and physician-initiated password resets.

CREATE TABLE IF NOT EXISTS public.invites (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_by integer NOT NULL,
    token_hash character varying(64) NOT NULL UNIQUE,
    invite_code character varying(32) NOT NULL UNIQUE,
    intended_role character varying(20) NOT NULL,
    is_used boolean DEFAULT false NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT invites_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id) ON DELETE RESTRICT,
    CONSTRAINT invites_role_check CHECK (intended_role IN ('DOCTOR', 'PATIENT'))
);

CREATE INDEX IF NOT EXISTS ix_invites_token_hash ON public.invites USING btree (token_hash);
CREATE INDEX IF NOT EXISTS ix_invites_code ON public.invites USING btree (invite_code);
