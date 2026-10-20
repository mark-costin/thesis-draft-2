-- Table: doctors
-- Purpose: Professional credentials, licensing, and clinic profile for attending and clinic owner physicians.

CREATE TABLE IF NOT EXISTS public.doctors (
    doctor_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id integer NOT NULL UNIQUE,
    first_name character varying(100) NOT NULL,
    middle_name character varying(100),
    last_name character varying(100) NOT NULL,
    suffix character varying(20),
    address text NOT NULL,
    specialization character varying(100) NOT NULL,
    hospital_affiliation character varying(255),
    license_number character varying(50) NOT NULL UNIQUE,
    contact_number character varying(20) NOT NULL,
    email character varying(150) NOT NULL UNIQUE,
    emergency_contact_name character varying(150) NOT NULL,
    emergency_contact_number character varying(20) NOT NULL,
    emergency_relation character varying(50) NOT NULL,
    is_verified boolean DEFAULT false NOT NULL,
    date_of_birth date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT doctors_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS ix_doctors_user_id ON public.doctors USING btree (user_id);
