-- Table: model_versions
-- Purpose: Tracks deployed XGBoost model artifacts, feature configurations, sha256 checksums, and version tags.

CREATE TABLE IF NOT EXISTS public.model_versions (
    model_version_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    disease_domain character varying(10) NOT NULL,
    version character varying(30) NOT NULL,
    algorithm character varying(50) DEFAULT 'XGBoost' NOT NULL,
    artifact_path text NOT NULL,
    artifact_sha256 character(64) NOT NULL,
    feature_list jsonb NOT NULL,
    metrics jsonb,
    trained_at timestamp with time zone,
    is_active boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT model_versions_disease_domain_check CHECK (disease_domain IN ('CVD', 'T2D', 'CRD', 'NEURO')),
    CONSTRAINT model_versions_disease_domain_version_key UNIQUE (disease_domain, version)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_model_versions_one_active ON public.model_versions USING btree (disease_domain) WHERE is_active;
