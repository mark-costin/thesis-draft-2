-- Table: queue_tickets
-- Purpose: Manages live on-premise consultation order, wait times, and status synchronization over WebSockets.

CREATE TABLE IF NOT EXISTS public.queue_tickets (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    queue_date date NOT NULL,
    queue_number integer NOT NULL,
    patient_id integer NOT NULL,
    doctor_id integer,
    name character varying(150) NOT NULL,
    urgency character varying(40) NOT NULL DEFAULT 'Normal',
    complaint text NOT NULL,
    vitals character varying(255),
    watch_flag character varying(150),
    status character varying(12) NOT NULL DEFAULT 'WAITING',
    checked_in_at timestamp with time zone NOT NULL DEFAULT now(),
    called_at timestamp with time zone,
    closed_at timestamp with time zone,
    CONSTRAINT queue_tickets_patient_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(patient_id) ON DELETE RESTRICT,
    CONSTRAINT queue_tickets_doctor_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(doctor_id) ON DELETE RESTRICT,
    CONSTRAINT queue_tickets_status_check CHECK (status IN ('WAITING', 'IN_CONSULTATION', 'DONE', 'CANCELLED')),
    CONSTRAINT queue_tickets_number_unique UNIQUE (queue_date, queue_number)
);

CREATE INDEX IF NOT EXISTS ix_queue_tickets_patient_id ON public.queue_tickets USING btree (patient_id);
CREATE INDEX IF NOT EXISTS ix_queue_tickets_queue_date ON public.queue_tickets USING btree (queue_date);
