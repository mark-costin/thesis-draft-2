-- Table: care_plan_tasks
-- Purpose: Daily preventive lifestyle targets prescribed by the doctor that patients tick off in their portal.

CREATE TABLE IF NOT EXISTS public.care_plan_tasks (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    consultation_id integer NOT NULL,
    patient_id integer NOT NULL,
    task_description character varying(255) NOT NULL,
    target_metric character varying(100),
    is_completed boolean DEFAULT false NOT NULL,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT care_plan_tasks_consultation_fkey FOREIGN KEY (consultation_id) REFERENCES public.consultations(id) ON DELETE RESTRICT,
    CONSTRAINT care_plan_tasks_patient_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(patient_id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS ix_care_plan_tasks_patient ON public.care_plan_tasks USING btree (patient_id);
CREATE INDEX IF NOT EXISTS ix_care_plan_tasks_consultation ON public.care_plan_tasks USING btree (consultation_id);
