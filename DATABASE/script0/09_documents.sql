-- Table: documents
-- Purpose: Tracks uploaded scanned lab reports, Chandra OCR jobs, status states, and local Docker volume file paths.

CREATE TABLE IF NOT EXISTS public.documents (
    document_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id integer NOT NULL,
    consultation_id integer,
    uploaded_by integer NOT NULL,
    document_type character varying(50) DEFAULT 'medical_record' NOT NULL,
    file_path text NOT NULL,
    mime_type character varying(100),
    file_sha256 character(64) NOT NULL,
    ocr_engine character varying(50) DEFAULT 'Chandra OCR',
    ocr_text text,
    ocr_confidence numeric(5,2),
    status character varying(20) DEFAULT 'pending' NOT NULL,
    verified_by integer,
    verified_at timestamp with time zone,
    uploaded_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT documents_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(patient_id) ON DELETE RESTRICT,
    CONSTRAINT documents_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.users(user_id) ON DELETE RESTRICT,
    CONSTRAINT documents_verified_by_fkey FOREIGN KEY (verified_by) REFERENCES public.users(user_id) ON DELETE RESTRICT,
    CONSTRAINT documents_consultation_fkey FOREIGN KEY (consultation_id) REFERENCES public.consultations(id) ON DELETE RESTRICT,
    CONSTRAINT documents_status_check CHECK (status IN ('pending', 'verified', 'rejected')),
    CONSTRAINT documents_ocr_confidence_check CHECK (ocr_confidence >= 0 AND ocr_confidence <= 100),
    CONSTRAINT documents_verification_check CHECK (status <> 'verified' OR (verified_by IS NOT NULL AND verified_at IS NOT NULL))
);

CREATE INDEX IF NOT EXISTS ix_documents_patient_id ON public.documents USING btree (patient_id);
CREATE INDEX IF NOT EXISTS ix_documents_status ON public.documents USING btree (status);
CREATE INDEX IF NOT EXISTS ix_documents_consultation_id ON public.documents USING btree (consultation_id);
