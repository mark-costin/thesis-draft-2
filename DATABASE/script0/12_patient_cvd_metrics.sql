-- Table: patient_cvd_metrics
-- Purpose: Clinical biometrics and lab inputs specifically evaluated by the CVD/Hypertension XGBoost model.

CREATE TABLE IF NOT EXISTS public.patient_cvd_metrics (
    metric_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id integer NOT NULL,
    consultation_id integer,
    age numeric NOT NULL,
    biological_sex character varying(20) NOT NULL,
    sbp numeric NOT NULL,
    dbp numeric NOT NULL,
    bmi numeric NOT NULL,
    resting_hr numeric NOT NULL,
    total_cholesterol numeric NOT NULL,
    hdl numeric NOT NULL,
    ldl numeric NOT NULL,
    triglycerides numeric NOT NULL,
    hs_crp numeric,
    serum_creatinine numeric,
    egfr numeric,
    lvef numeric,
    ctni numeric,
    nt_probnp numeric,
    smoking_history numeric NOT NULL,
    daily_sodium numeric,
    family_history_premature_cvd integer NOT NULL,
    physical_activity numeric,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT patient_cvd_metrics_patient_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(patient_id) ON DELETE RESTRICT,
    CONSTRAINT patient_cvd_metrics_consultation_fkey FOREIGN KEY (consultation_id) REFERENCES public.consultations(id) ON DELETE RESTRICT,
    CONSTRAINT patient_cvd_metrics_age_check CHECK (age >= 18 AND age <= 100),
    CONSTRAINT patient_cvd_metrics_biological_sex_check CHECK (biological_sex IN ('Female', 'Male')),
    CONSTRAINT patient_cvd_metrics_bmi_check CHECK (bmi >= 12.0 AND bmi <= 60.0),
    CONSTRAINT patient_cvd_metrics_sbp_check CHECK (sbp >= 70 AND sbp <= 220),
    CONSTRAINT patient_cvd_metrics_dbp_check CHECK (dbp >= 40 AND dbp <= 130),
    CONSTRAINT patient_cvd_metrics_resting_hr_check CHECK (resting_hr >= 40 AND resting_hr <= 180),
    CONSTRAINT patient_cvd_metrics_total_cholesterol_check CHECK (total_cholesterol >= 100 AND total_cholesterol <= 400),
    CONSTRAINT patient_cvd_metrics_hdl_check CHECK (hdl >= 15 AND hdl <= 120),
    CONSTRAINT patient_cvd_metrics_ldl_check CHECK (ldl >= 30 AND ldl <= 300),
    CONSTRAINT patient_cvd_metrics_triglycerides_check CHECK (triglycerides >= 40 AND triglycerides <= 1000)
);

CREATE INDEX IF NOT EXISTS ix_cvd_metrics_patient_recorded ON public.patient_cvd_metrics USING btree (patient_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS ix_cvd_metrics_consultation_id ON public.patient_cvd_metrics USING btree (consultation_id);
