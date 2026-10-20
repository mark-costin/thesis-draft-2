-- Table: consultations
-- Purpose: Physician clinical encounters, SOAP consultation notes, diagnostic impressions, and care plan directives.

CREATE TABLE IF NOT EXISTS public.consultations (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    consultation_uid character varying(64) NOT NULL UNIQUE,
    patient_id integer NOT NULL,
    doctor_id integer NOT NULL,
    notes text,
    directives json NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT consultations_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(patient_id) ON DELETE RESTRICT,
    CONSTRAINT consultations_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(doctor_id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS ix_consultations_patient_id ON public.consultations USING btree (patient_id);
CREATE INDEX IF NOT EXISTS ix_consultations_doctor_id ON public.consultations USING btree (doctor_id);
