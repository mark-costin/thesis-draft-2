-- Table: audit_ledger
-- Purpose: Tamper-evident operational audit logs for statutory compliance and Break-Glass event monitoring.

CREATE TABLE IF NOT EXISTS public.audit_ledger (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    audit_id character varying(64) NOT NULL UNIQUE,
    timestamp_utc timestamp with time zone NOT NULL DEFAULT now(),
    event_type character varying(64) NOT NULL,
    payload json NOT NULL,
    patient_id integer,
    doctor_id integer,
    actor_user_id integer,
    entry_seal character varying(64) NOT NULL,
    CONSTRAINT audit_ledger_actor_fkey FOREIGN KEY (actor_user_id) REFERENCES public.users(user_id) ON DELETE RESTRICT,
    CONSTRAINT audit_ledger_doctor_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(doctor_id) ON DELETE RESTRICT,
    CONSTRAINT audit_ledger_patient_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(patient_id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS ix_audit_ledger_timestamp_utc ON public.audit_ledger USING btree (timestamp_utc);
CREATE INDEX IF NOT EXISTS ix_audit_ledger_event_type ON public.audit_ledger USING btree (event_type);
CREATE INDEX IF NOT EXISTS ix_audit_ledger_patient_id ON public.audit_ledger USING btree (patient_id);
CREATE INDEX IF NOT EXISTS ix_audit_ledger_doctor_id ON public.audit_ledger USING btree (doctor_id);
