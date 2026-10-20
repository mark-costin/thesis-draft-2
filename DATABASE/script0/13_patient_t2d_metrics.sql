-- Table: patient_t2d_metrics
-- Purpose: Clinical biometrics, glycemic panels, and metabolic variables for the Type 2 Diabetes XGBoost model.

CREATE TABLE IF NOT EXISTS public.patient_t2d_metrics (
    metric_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id integer NOT NULL,
    consultation_id integer,
    fpg numeric(5,1) NOT NULL,
    postprandial_glucose_2h numeric(5,1),
    hba1c numeric(4,1) NOT NULL,
    fasting_insulin numeric(5,1),
    c_peptide numeric(4,1),
    homa_ir numeric(4,1),
    bmi numeric(4,1) NOT NULL,
    waist_circumference numeric(5,1),
    whr numeric(4,2),
    sbp numeric(5,1) NOT NULL,
    dbp numeric(5,1) NOT NULL,
    triglycerides numeric(6,1) NOT NULL,
    hdl numeric(5,1) NOT NULL,
    uacr numeric(6,1),
    serum_uric_acid numeric(4,1),
    gestational_diabetes integer DEFAULT 0,
    family_history_diabetes integer NOT NULL,
    acanthosis_nigricans integer DEFAULT 0,
    daily_carbs numeric(5,1),
    sedentary_duration numeric(4,1),
    recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT patient_t2d_metrics_patient_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(patient_id) ON DELETE RESTRICT,
    CONSTRAINT patient_t2d_metrics_consultation_fkey FOREIGN KEY (consultation_id) REFERENCES public.consultations(id) ON DELETE RESTRICT,
    CONSTRAINT patient_t2d_metrics_fpg_check CHECK (fpg >= 50.0 AND fpg <= 450.0),
    CONSTRAINT patient_t2d_metrics_hba1c_check CHECK (hba1c >= 4.0 AND hba1c <= 15.0),
    CONSTRAINT patient_t2d_metrics_bmi_check CHECK (bmi >= 12.0 AND bmi <= 60.0),
    CONSTRAINT patient_t2d_metrics_sbp_check CHECK (sbp >= 70.0 AND sbp <= 220.0),
    CONSTRAINT patient_t2d_metrics_dbp_check CHECK (dbp >= 40.0 AND dbp <= 130.0)
);

CREATE INDEX IF NOT EXISTS ix_t2d_metrics_patient_recorded ON public.patient_t2d_metrics USING btree (patient_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS ix_t2d_metrics_consultation_id ON public.patient_t2d_metrics USING btree (consultation_id);
