-- Table: patient_family_history
-- Purpose: Normalized family pedigree entries by relative, kinship degree, and early-onset condition.

CREATE TABLE IF NOT EXISTS public.patient_family_history (
    record_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id integer NOT NULL,
    disease_domain character varying(100) NOT NULL,
    specific_diagnosis character varying(150) NOT NULL,
    relationship_tier character varying(50) NOT NULL,
    relationship_weight numeric NOT NULL,
    onset_classification character varying(50) NOT NULL,
    onset_weight numeric NOT NULL,
    age_at_diagnosis integer,
    shared_environment boolean DEFAULT false,
    is_verified boolean DEFAULT false NOT NULL,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT patient_family_history_patient_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(patient_id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS ix_family_history_patient_id ON public.patient_family_history USING btree (patient_id);
