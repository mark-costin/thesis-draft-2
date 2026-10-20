-- Table: patient_fhrs_stratification
-- Purpose: Aggregated pedigree score calculations and risk bands feeding the ML FeatureBuilder.

CREATE TABLE IF NOT EXISTS public.patient_fhrs_stratification (
    fhrs_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id integer NOT NULL,
    consultation_id integer,
    disease_domain character varying(100) NOT NULL,
    clustering_score numeric NOT NULL,
    environmental_modifier numeric NOT NULL,
    calculated_fhrs numeric NOT NULL,
    risk_code integer NOT NULL,
    risk_category character varying(50) NOT NULL,
    evaluated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT patient_fhrs_patient_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(patient_id) ON DELETE RESTRICT,
    CONSTRAINT patient_fhrs_consultation_fkey FOREIGN KEY (consultation_id) REFERENCES public.consultations(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS ix_fhrs_patient_evaluated ON public.patient_fhrs_stratification USING btree (patient_id, evaluated_at DESC);
CREATE INDEX IF NOT EXISTS ix_fhrs_consultation_id ON public.patient_fhrs_stratification USING btree (consultation_id);
