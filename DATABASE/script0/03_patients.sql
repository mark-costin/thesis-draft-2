-- Table: patients
-- Purpose: Demographic information, emergency contacts, and statutory consent records.

CREATE TABLE IF NOT EXISTS public.patients (
    patient_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id integer NOT NULL UNIQUE,
    first_name character varying(100) NOT NULL,
    middle_name character varying(100),
    last_name character varying(100) NOT NULL,
    suffix character varying(20),
    date_of_birth date NOT NULL,
    biological_sex character varying(10) NOT NULL,
    gender character varying(20) NOT NULL,
    religion character varying(50),
    address text NOT NULL,
    contact_number character varying(20) NOT NULL,
    email character varying(150) NOT NULL UNIQUE,
    emergency_contact_name character varying(150) NOT NULL,
    emergency_contact_number character varying(20) NOT NULL,
    emergency_relation character varying(50) NOT NULL,
    hipaa_consent boolean NOT NULL,
    hipaa_consent_at timestamp with time zone DEFAULT now(),
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT patients_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE RESTRICT,
    CONSTRAINT patients_biological_sex_check CHECK (biological_sex IN ('Female', 'Male'))
);

CREATE INDEX IF NOT EXISTS ix_patients_user_id ON public.patients USING btree (user_id);
