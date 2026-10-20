-- Table: patient_respiratory_metrics
-- Purpose: Pulmonary function values, spirometry, and clinical biomarkers for the Chronic Respiratory Disease model.

CREATE TABLE IF NOT EXISTS public.patient_respiratory_metrics (
    metric_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id integer NOT NULL,
    consultation_id integer,
    fev1 numeric(3,1),
    fvc numeric(3,1),
    fev1_fvc_ratio numeric(4,1),
    post_bd_fev1_pred numeric(5,1),
    pef numeric(5,1),
    eosinophil_count numeric(6,1),
    feno numeric(5,1),
    spo2 numeric(4,1) NOT NULL,
    pao2 numeric(5,1),
    paco2 numeric(4,1),
    mmrc_score integer,
    act_score integer,
    cat_score integer,
    serum_ige numeric(6,1),
    annual_exacerbations integer DEFAULT 0,
    tobacco_exposure numeric(5,1) NOT NULL,
    occupational_dust integer DEFAULT 0,
    allergic_rhinitis integer DEFAULT 0,
    childhood_asthma integer DEFAULT 0,
    bmi numeric(4,1) NOT NULL,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT patient_resp_metrics_patient_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(patient_id) ON DELETE RESTRICT,
    CONSTRAINT patient_resp_metrics_consultation_fkey FOREIGN KEY (consultation_id) REFERENCES public.consultations(id) ON DELETE RESTRICT,
    CONSTRAINT patient_respiratory_metrics_spo2_check CHECK (spo2 >= 65.0 AND spo2 <= 100.0),
    CONSTRAINT patient_respiratory_metrics_bmi_check CHECK (bmi >= 12.0 AND bmi <= 60.0)
);

CREATE INDEX IF NOT EXISTS ix_resp_metrics_patient_recorded ON public.patient_respiratory_metrics USING btree (patient_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS ix_resp_metrics_consultation_id ON public.patient_respiratory_metrics USING btree (consultation_id);
