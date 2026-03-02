-- ============================================================
--  HomeoClinic — Supabase PostgreSQL Schema
--  Run this in your Supabase SQL Editor
-- ============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─────────────────────────────────────────────────────────────
-- 1. PROFILES (extends auth.users)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role        TEXT NOT NULL DEFAULT 'patient'
                   CHECK (role IN ('doctor', 'staff', 'patient')),
  full_name   TEXT NOT NULL DEFAULT '',
  phone       TEXT,
  avatar_url  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-create profile on sign-up
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'full_name', ''));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ─────────────────────────────────────────────────────────────
-- 2. PATIENTS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS patients (
  id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id           UUID REFERENCES profiles(id),
  patient_code         TEXT UNIQUE,
  full_name            TEXT NOT NULL,
  dob                  DATE,
  gender               TEXT DEFAULT 'unknown',
  blood_group          TEXT,
  phone                TEXT,
  email                TEXT,
  address              TEXT,
  referred_by          TEXT,
  case_number          TEXT,
  avatar_url           TEXT,
  chief_complaint      TEXT,
  medical_history      TEXT,
  allergies            TEXT,
  current_medications  TEXT,
  created_by           UUID REFERENCES profiles(id),
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-generate patient_code: HP-0001, HP-0002 …
CREATE SEQUENCE IF NOT EXISTS patient_code_seq;

CREATE OR REPLACE FUNCTION set_patient_code()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.patient_code IS NULL THEN
    NEW.patient_code := 'HP-' || LPAD(NEXTVAL('patient_code_seq')::TEXT, 4, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS before_patient_insert ON patients;
CREATE TRIGGER before_patient_insert
  BEFORE INSERT ON patients
  FOR EACH ROW EXECUTE FUNCTION set_patient_code();

-- ─────────────────────────────────────────────────────────────
-- 3. APPOINTMENTS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS appointments (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id    UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  doctor_id     UUID NOT NULL REFERENCES profiles(id),
  staff_id      UUID REFERENCES profiles(id),
  scheduled_at  TIMESTAMPTZ NOT NULL,
  status        TEXT NOT NULL DEFAULT 'scheduled'
                     CHECK (status IN ('scheduled','waiting','in_progress','completed','cancelled')),
  queue_number  INTEGER NOT NULL DEFAULT 0,
  notes         TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-assign queue number (per-day, per-doctor)
CREATE OR REPLACE FUNCTION assign_queue_number()
RETURNS TRIGGER AS $$
DECLARE
  next_num INTEGER;
BEGIN
  SELECT COALESCE(MAX(queue_number), 0) + 1
    INTO next_num
    FROM appointments
   WHERE doctor_id = NEW.doctor_id
     AND scheduled_at::DATE = NEW.scheduled_at::DATE;
  NEW.queue_number := next_num;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS before_appointment_insert ON appointments;
CREATE TRIGGER before_appointment_insert
  BEFORE INSERT ON appointments
  FOR EACH ROW EXECUTE FUNCTION assign_queue_number();

-- ─────────────────────────────────────────────────────────────
-- 4. VITALS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vitals (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  appointment_id  UUID NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
  patient_id      UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  weight          NUMERIC(5,2),
  height          NUMERIC(5,2),
  bp_systolic     INTEGER,
  bp_diastolic    INTEGER,
  pulse           INTEGER,
  temperature     NUMERIC(4,1),
  spo2            INTEGER,
  recorded_by     UUID REFERENCES profiles(id),
  recorded_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────
-- 5. PRESCRIPTIONS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS prescriptions (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  appointment_id   UUID NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
  patient_id       UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  doctor_id        UUID NOT NULL REFERENCES profiles(id),
  chief_complaint  TEXT,
  diagnosis        TEXT,
  miasm            TEXT,
  remedy_json      JSONB NOT NULL DEFAULT '[]',
  follow_up_date   DATE,
  notes            TEXT,
  pdf_url          TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────
-- 6. LAB REPORTS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lab_reports (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id      UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  appointment_id  UUID REFERENCES appointments(id),
  report_type     TEXT NOT NULL DEFAULT 'general',
  file_url        TEXT NOT NULL,
  file_name       TEXT NOT NULL,
  uploaded_by     UUID REFERENCES profiles(id),
  report_date     DATE NOT NULL DEFAULT CURRENT_DATE,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────
-- 7. PATIENT MEDIA
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS patient_media (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id   UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  media_type   TEXT NOT NULL DEFAULT 'other'
                    CHECK (media_type IN ('before','after','xray','other')),
  file_url     TEXT NOT NULL,
  caption      TEXT,
  uploaded_by  UUID REFERENCES profiles(id),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────
-- 8. COMMISSIONS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS commissions (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id        UUID NOT NULL REFERENCES profiles(id),
  patient_id      UUID NOT NULL REFERENCES patients(id),
  appointment_id  UUID REFERENCES appointments(id),
  amount          NUMERIC(10,2) NOT NULL DEFAULT 0,
  percentage      NUMERIC(5,2) NOT NULL DEFAULT 10,
  status          TEXT NOT NULL DEFAULT 'pending'
                       CHECK (status IN ('pending','paid')),
  paid_at         TIMESTAMPTZ,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────
-- 9. NOTIFICATIONS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  recipient_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title         TEXT NOT NULL,
  body          TEXT NOT NULL,
  type          TEXT NOT NULL DEFAULT 'general',
  reference_id  UUID,
  is_read       BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notification_tokens (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  fcm_token   TEXT NOT NULL,
  platform    TEXT NOT NULL DEFAULT 'android',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, fcm_token)
);

-- ─────────────────────────────────────────────────────────────
-- 10. ROW LEVEL SECURITY (RLS)
-- ─────────────────────────────────────────────────────────────

-- Helper: get current user's role
CREATE OR REPLACE FUNCTION current_user_role()
RETURNS TEXT AS $$
  SELECT role FROM profiles WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER;

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE vitals ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE lab_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE commissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_tokens ENABLE ROW LEVEL SECURITY;

-- PROFILES
CREATE POLICY profiles_self_read ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY profiles_staff_doctor_read ON profiles FOR SELECT USING (current_user_role() IN ('doctor', 'staff'));
CREATE POLICY profiles_self_update ON profiles FOR UPDATE USING (auth.uid() = id);

-- PATIENTS
CREATE POLICY patients_staff_doctor ON patients FOR ALL USING (current_user_role() IN ('doctor', 'staff'));
CREATE POLICY patients_own_read ON patients FOR SELECT USING (profile_id = auth.uid());

-- APPOINTMENTS
CREATE POLICY appt_staff_doctor ON appointments FOR ALL USING (current_user_role() IN ('doctor', 'staff'));
CREATE POLICY appt_patient_read ON appointments FOR SELECT USING (
  patient_id IN (SELECT id FROM patients WHERE profile_id = auth.uid())
);

-- VITALS
CREATE POLICY vitals_staff_doctor ON vitals FOR ALL USING (current_user_role() IN ('doctor', 'staff'));
CREATE POLICY vitals_patient_read ON vitals FOR SELECT USING (
  patient_id IN (SELECT id FROM patients WHERE profile_id = auth.uid())
);

-- PRESCRIPTIONS
CREATE POLICY rx_doctor_write ON prescriptions FOR ALL USING (current_user_role() = 'doctor');
CREATE POLICY rx_staff_read ON prescriptions FOR SELECT USING (current_user_role() = 'staff');
CREATE POLICY rx_patient_read ON prescriptions FOR SELECT USING (
  patient_id IN (SELECT id FROM patients WHERE profile_id = auth.uid())
);

-- LAB REPORTS
CREATE POLICY reports_staff_doctor ON lab_reports FOR ALL USING (current_user_role() IN ('doctor', 'staff'));
CREATE POLICY reports_patient_read ON lab_reports FOR SELECT USING (
  patient_id IN (SELECT id FROM patients WHERE profile_id = auth.uid())
);

-- PATIENT MEDIA
CREATE POLICY media_staff_doctor ON patient_media FOR ALL USING (current_user_role() IN ('doctor', 'staff'));
CREATE POLICY media_patient_read ON patient_media FOR SELECT USING (
  patient_id IN (SELECT id FROM patients WHERE profile_id = auth.uid())
);

-- COMMISSIONS
CREATE POLICY comm_doctor ON commissions FOR ALL USING (current_user_role() = 'doctor');
CREATE POLICY comm_staff_read ON commissions FOR SELECT USING (staff_id = auth.uid());

-- NOTIFICATIONS
CREATE POLICY notif_own ON notifications FOR ALL USING (recipient_id = auth.uid());

-- NOTIFICATION TOKENS
CREATE POLICY token_own ON notification_tokens FOR ALL USING (user_id = auth.uid());

-- ─────────────────────────────────────────────────────────────
-- 11. ANALYTICS RPC FUNCTIONS
-- ─────────────────────────────────────────────────────────────

-- Total appointments in a date range
CREATE OR REPLACE FUNCTION get_appointment_stats(from_date DATE, to_date DATE)
RETURNS JSON AS $$
  SELECT JSON_BUILD_OBJECT(
    'total', COUNT(*),
    'completed', SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END),
    'cancelled', SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END)
  )
  FROM appointments
  WHERE scheduled_at::DATE BETWEEN from_date AND to_date;
$$ LANGUAGE SQL SECURITY DEFINER;

-- New patients per month for last N months
CREATE OR REPLACE FUNCTION get_patient_growth(months INTEGER DEFAULT 6)
RETURNS TABLE(month TEXT, count BIGINT) AS $$
  SELECT TO_CHAR(created_at, 'Mon YYYY'), COUNT(*)
  FROM patients
  WHERE created_at >= NOW() - (months || ' months')::INTERVAL
  GROUP BY TO_CHAR(created_at, 'Mon YYYY'), DATE_TRUNC('month', created_at)
  ORDER BY DATE_TRUNC('month', created_at);
$$ LANGUAGE SQL SECURITY DEFINER;

-- Top prescribed remedies
CREATE OR REPLACE FUNCTION get_top_remedies(lim INTEGER DEFAULT 10)
RETURNS TABLE(remedy_name TEXT, count BIGINT) AS $$
  SELECT elem->>'remedy_name', COUNT(*)
  FROM prescriptions,
       JSONB_ARRAY_ELEMENTS(remedy_json) AS elem
  GROUP BY elem->>'remedy_name'
  ORDER BY COUNT(*) DESC
  LIMIT lim;
$$ LANGUAGE SQL SECURITY DEFINER;

-- ─────────────────────────────────────────────────────────────
-- 12. SUPABASE STORAGE BUCKETS (run via Supabase dashboard or CLI)
-- ─────────────────────────────────────────────────────────────
-- INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('lab-reports', 'lab-reports', false);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('patient-media', 'patient-media', false);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('prescription-pdfs', 'prescription-pdfs', false);

