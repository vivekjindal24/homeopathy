-- =============================================================================
-- 002_schema_fixes.sql
-- Homeopathy Clinic – Schema fixes: missing columns, broken FK relationships,
-- and duplicate-appointment prevention.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. patients — add missing columns used by the Dart PatientModel
-- ---------------------------------------------------------------------------

-- patient_code: human-readable unique identifier (e.g. "P1001")
ALTER TABLE public.patients
    ADD COLUMN IF NOT EXISTS patient_code      TEXT UNIQUE,
    ADD COLUMN IF NOT EXISTS email             TEXT,
    ADD COLUMN IF NOT EXISTS referred_by       TEXT,
    ADD COLUMN IF NOT EXISTS case_number       TEXT,
    ADD COLUMN IF NOT EXISTS avatar_url        TEXT,
    ADD COLUMN IF NOT EXISTS chief_complaint   TEXT,
    ADD COLUMN IF NOT EXISTS medical_history   TEXT,
    ADD COLUMN IF NOT EXISTS allergies         TEXT,
    ADD COLUMN IF NOT EXISTS current_medications TEXT;

-- Sequence to generate monotonically-increasing patient codes.
CREATE SEQUENCE IF NOT EXISTS public.patient_code_seq START 1001 INCREMENT 1;

-- Back-fill existing rows that have no patient_code yet.
UPDATE public.patients
SET    patient_code = 'P' || LPAD(nextval('public.patient_code_seq')::TEXT, 4, '0')
WHERE  patient_code IS NULL;

-- From here on, every new patient gets a code automatically.
CREATE OR REPLACE FUNCTION public.generate_patient_code()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.patient_code IS NULL OR NEW.patient_code = '' THEN
        NEW.patient_code :=
            'P' || LPAD(nextval('public.patient_code_seq')::TEXT, 4, '0');
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_patients_patient_code ON public.patients;
CREATE TRIGGER trg_patients_patient_code
    BEFORE INSERT ON public.patients
    FOR EACH ROW EXECUTE FUNCTION public.generate_patient_code();

-- ---------------------------------------------------------------------------
-- 2. appointments — add missing columns used by the Dart AppointmentModel
-- ---------------------------------------------------------------------------

ALTER TABLE public.appointments
    ADD COLUMN IF NOT EXISTS staff_id     UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS queue_number INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS notes        TEXT;

-- Extend status constraint to also allow 'waiting' (used by the Dart model).
ALTER TABLE public.appointments
    DROP CONSTRAINT IF EXISTS appointments_status_check;
ALTER TABLE public.appointments
    ADD CONSTRAINT appointments_status_check
    CHECK (status IN ('scheduled', 'waiting', 'in_progress',
                      'completed', 'cancelled', 'no_show'));

-- ---------------------------------------------------------------------------
-- 3. appointments — prevent duplicate bookings
--    A patient cannot have two appointments at the exact same timestamp.
-- ---------------------------------------------------------------------------
ALTER TABLE public.appointments
    DROP CONSTRAINT IF EXISTS uq_appointments_patient_scheduled;
ALTER TABLE public.appointments
    ADD CONSTRAINT uq_appointments_patient_scheduled
    UNIQUE (patient_id, scheduled_at);

-- ---------------------------------------------------------------------------
-- 4. vitals — add appointment_id FK and height column
--    The Dart model (VitalsModel) uses appointment_id, not visit_id.
-- ---------------------------------------------------------------------------
ALTER TABLE public.vitals
    ADD COLUMN IF NOT EXISTS appointment_id UUID
        REFERENCES public.appointments(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS height NUMERIC(5, 1);

-- Allow upsert by appointment_id (used in vitals_repository.dart).
DROP INDEX IF EXISTS public.idx_vitals_appointment_id;
CREATE UNIQUE INDEX IF NOT EXISTS idx_vitals_appointment_id
    ON public.vitals (appointment_id)
    WHERE appointment_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 5. prescriptions — add appointment_id FK and the columns used by
--    PrescriptionModel (chief_complaint, diagnosis, miasm, remedy_json,
--    follow_up_date, notes).
-- ---------------------------------------------------------------------------
ALTER TABLE public.prescriptions
    ADD COLUMN IF NOT EXISTS appointment_id  UUID
        REFERENCES public.appointments(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS chief_complaint TEXT,
    ADD COLUMN IF NOT EXISTS diagnosis       TEXT,
    ADD COLUMN IF NOT EXISTS miasm           TEXT,
    ADD COLUMN IF NOT EXISTS remedy_json     JSONB NOT NULL DEFAULT '[]',
    ADD COLUMN IF NOT EXISTS follow_up_date  DATE,
    ADD COLUMN IF NOT EXISTS notes           TEXT;

-- ---------------------------------------------------------------------------
-- 6. notifications & notification_tokens tables (referenced in constants.dart
--    but missing from the initial migration).
--    Column names match the Dart NotificationModel and NotificationRepository.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notifications (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title         TEXT NOT NULL,
    body          TEXT,
    type          TEXT NOT NULL DEFAULT 'general',
    reference_id  UUID,
    data          JSONB,
    is_read       BOOLEAN NOT NULL DEFAULT false,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.notification_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    token       TEXT NOT NULL UNIQUE,
    platform    TEXT CHECK (platform IN ('android', 'ios', 'web')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS for notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notifications_select"
    ON public.notifications FOR SELECT
    TO authenticated
    USING (recipient_id = auth.uid());

CREATE POLICY "notifications_insert"
    ON public.notifications FOR INSERT
    TO authenticated
    WITH CHECK (true);  -- edge function inserts on behalf of users

CREATE POLICY "notifications_update"
    ON public.notifications FOR UPDATE
    TO authenticated
    USING (recipient_id = auth.uid())
    WITH CHECK (recipient_id = auth.uid());

-- RLS for notification_tokens
ALTER TABLE public.notification_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notification_tokens_all"
    ON public.notification_tokens FOR ALL
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- updated_at trigger for notification_tokens
CREATE TRIGGER trg_notification_tokens_updated_at
    BEFORE UPDATE ON public.notification_tokens
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- 7. lab_reports — add columns used by the Dart LabReportModel
--    DB originally had: test_name (NOT NULL), visit_id, lab_id, file_type, etc.
--    Dart model uses:   report_type, file_name, appointment_id
-- ---------------------------------------------------------------------------
ALTER TABLE public.lab_reports
    ADD COLUMN IF NOT EXISTS report_type    TEXT,
    ADD COLUMN IF NOT EXISTS file_name      TEXT,
    ADD COLUMN IF NOT EXISTS appointment_id UUID
        REFERENCES public.appointments(id) ON DELETE SET NULL;

-- test_name is NOT NULL in the initial schema but the LabReportModel inserts
-- using report_type/file_name instead. Set an empty-string default so that
-- rows inserted by the Dart code don't violate the NOT NULL constraint.
ALTER TABLE public.lab_reports
    ALTER COLUMN test_name SET DEFAULT '';

-- ---------------------------------------------------------------------------
-- 8. commissions — add columns used by CommissionModel / CommissionRepository
--    DB originally had: lab_report_id, lab_id, doctor_id, commission_percentage,
--                        commission_amount, month_year, status
--    Dart model uses:   staff_id, patient_id, appointment_id, amount,
--                        percentage, paid_at, staff_name, patient_name
-- ---------------------------------------------------------------------------
ALTER TABLE public.commissions
    ADD COLUMN IF NOT EXISTS staff_id      UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS patient_id    UUID REFERENCES public.patients(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS appointment_id UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS amount        NUMERIC(10, 2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS percentage    NUMERIC(5, 2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS paid_at       TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS staff_name    TEXT,
    ADD COLUMN IF NOT EXISTS patient_name  TEXT;

-- ---------------------------------------------------------------------------
-- 9. Indexes for common query patterns
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_appointments_patient_id
    ON public.appointments (patient_id);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_id
    ON public.appointments (doctor_id);
CREATE INDEX IF NOT EXISTS idx_appointments_scheduled_at
    ON public.appointments (scheduled_at);
CREATE INDEX IF NOT EXISTS idx_patients_patient_code
    ON public.patients (patient_code);
CREATE INDEX IF NOT EXISTS idx_patients_phone
    ON public.patients (phone);
CREATE INDEX IF NOT EXISTS idx_vitals_patient_id
    ON public.vitals (patient_id);
CREATE INDEX IF NOT EXISTS idx_prescriptions_appointment_id
    ON public.prescriptions (appointment_id)
    WHERE appointment_id IS NOT NULL;

-- =============================================================================
-- END OF MIGRATION 002_schema_fixes.sql
-- =============================================================================
