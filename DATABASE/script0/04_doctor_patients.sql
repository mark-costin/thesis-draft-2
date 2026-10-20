-- Table: doctor_patients
-- Purpose: Relational bridge table enforcing clinician-patient clinical assignment and tenant isolation.

CREATE TABLE IF NOT EXISTS public.doctor_patients (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    doctor_id integer NOT NULL,
    patient_id integer NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    linked_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT doctor_patients_doctor_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(doctor_id) ON DELETE RESTRICT,
    CONSTRAINT doctor_patients_patient_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(patient_id) ON DELETE RESTRICT,
    CONSTRAINT doctor_patients_unique UNIQUE (doctor_id, patient_id)
);

CREATE INDEX IF NOT EXISTS ix_doctor_patients_doctor ON public.doctor_patients USING btree (doctor_id);
CREATE INDEX IF NOT EXISTS ix_doctor_patients_patient ON public.doctor_patients USING btree (patient_id);
