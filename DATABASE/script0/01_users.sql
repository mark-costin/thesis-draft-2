-- Table: users
-- Purpose: System credentials, authentication roles, account lockout tracking, and clinic ownership flag.
-- Context: Replaces dedicated admin roles; clinic owner doctor is flagged with is_owner = true.

CREATE TABLE IF NOT EXISTS public.users (
    user_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username character varying(150) NOT NULL UNIQUE,
    email character varying(150) NOT NULL UNIQUE,
    password_hash character varying(255) NOT NULL,
    role character varying(20) NOT NULL,
    is_owner boolean DEFAULT false NOT NULL,
    is_locked boolean DEFAULT false NOT NULL,
    failed_attempts integer DEFAULT 0 NOT NULL,
    token_version integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT users_failed_attempts_check CHECK (failed_attempts >= 0),
    CONSTRAINT users_role_check CHECK (role IN ('DOCTOR', 'PATIENT'))
);

CREATE INDEX IF NOT EXISTS ix_users_username ON public.users USING btree (username);
CREATE INDEX IF NOT EXISTS ix_users_email ON public.users USING btree (email);
