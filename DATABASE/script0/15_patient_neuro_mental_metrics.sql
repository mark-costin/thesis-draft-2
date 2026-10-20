-- Table: patient_neuro_mental_metrics
-- Purpose: Neurological indices, cognitive scores, and biometric variables for the Neuro/Mental Health model.

CREATE TABLE IF NOT EXISTS public.patient_neuro_mental_metrics (
    metric_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id integer NOT NULL,
    consultation_id integer,
    phq9 integer,
    gad7 integer,
    mmse integer,
    moca integer,
    ham_d integer,
    updrs_part3 integer,
    daily_sleep numeric(4,1),
    psqi integer,
    seizure_frequency numeric(5,1),
    hrv_sdnn numeric(5,1),
    serum_cortisol numeric(4,1),
    vitamin_b12 numeric(6,1),
    serum_folate numeric(4,1),
    tsh numeric(5,2),
    faq_score integer,
    tremor_rating integer,
    tbi_history integer DEFAULT 0,
    substance_abuse integer DEFAULT 0,
    family_history_neuro_psych integer NOT NULL,
    age numeric(4,1) NOT NULL,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT patient_neuro_metrics_patient_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(patient_id) ON DELETE RESTRICT,
    CONSTRAINT patient_neuro_metrics_consultation_fkey FOREIGN KEY (consultation_id) REFERENCES public.consultations(id) ON DELETE RESTRICT,
    CONSTRAINT patient_neuro_mental_metrics_age_check CHECK (age >= 18.0 AND age <= 100.0)
);

CREATE INDEX IF NOT EXISTS ix_neuro_metrics_patient_recorded ON public.patient_neuro_mental_metrics USING btree (patient_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS ix_neuro_metrics_consultation_id ON public.patient_neuro_mental_metrics USING btree (consultation_id);
