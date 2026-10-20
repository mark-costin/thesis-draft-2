-- Table: risk_results
-- Purpose: Stores the 4 disease screening probabilities, risk levels, and SHAP base values generated per consultation.

CREATE TABLE IF NOT EXISTS public.risk_results (
    result_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    consultation_id integer NOT NULL,
    model_version_id integer NOT NULL,
    disease_domain character varying(10) NOT NULL,
    risk_probability numeric(5,4) NOT NULL,
    risk_level character varying(20) NOT NULL,
    shap_base_value numeric,
    is_released boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT risk_results_consultation_fkey FOREIGN KEY (consultation_id) REFERENCES public.consultations(id) ON DELETE RESTRICT,
    CONSTRAINT risk_results_model_version_fkey FOREIGN KEY (model_version_id) REFERENCES public.model_versions(model_version_id) ON DELETE RESTRICT,
    CONSTRAINT risk_results_disease_domain_check CHECK (disease_domain IN ('CVD', 'T2D', 'CRD', 'NEURO')),
    CONSTRAINT risk_results_risk_level_check CHECK (risk_level IN ('Low', 'Moderate', 'High')),
    CONSTRAINT risk_results_risk_probability_check CHECK (risk_probability >= 0 AND risk_probability <= 1),
    CONSTRAINT risk_results_consultation_disease_key UNIQUE (consultation_id, disease_domain)
);

CREATE INDEX IF NOT EXISTS ix_risk_results_disease_level ON public.risk_results USING btree (disease_domain, risk_level);
CREATE INDEX IF NOT EXISTS ix_risk_results_model_version ON public.risk_results USING btree (model_version_id);
