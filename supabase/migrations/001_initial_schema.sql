-- =============================================================================
-- 001_initial_schema.sql
-- Homeopathy Clinic – Complete PostgreSQL Schema
-- =============================================================================
-- Run order: extensions → tables → indexes → triggers → RLS → realtime → storage → seed

-- ---------------------------------------------------------------------------
-- 0. Extensions
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";   -- for fuzzy search on names

-- ---------------------------------------------------------------------------
-- 1. TABLES
-- ---------------------------------------------------------------------------

-- 1.1  profiles  (mirrors auth.users 1-to-1)
CREATE TABLE IF NOT EXISTS public.profiles (
    id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name     TEXT NOT NULL,
    phone         TEXT UNIQUE,
    role          TEXT NOT NULL CHECK (role IN ('doctor', 'staff', 'patient')),
    avatar_url    TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.profiles IS 'One-to-one extension of auth.users with clinic-specific role.';

-- 1.2  patients
CREATE TABLE IF NOT EXISTS public.patients (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id          UUID REFERENCES public.profiles(id) ON DELETE SET NULL,  -- nullable for walk-ins
    full_name           TEXT NOT NULL,
    phone               TEXT NOT NULL UNIQUE,
    dob                 DATE,
    gender              TEXT CHECK (gender IN ('male', 'female', 'other')),
    address             TEXT,
    aadhaar_last4       TEXT CHECK (aadhaar_last4 ~ '^\d{4}$'),  -- exactly 4 digits
    disease_tags        TEXT[] NOT NULL DEFAULT '{}',
    blood_group         TEXT CHECK (blood_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
    emergency_contact   TEXT,
    created_by          UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON COLUMN public.patients.aadhaar_last4 IS 'Only last 4 digits of Aadhaar stored for privacy compliance.';

-- 1.3  appointments
CREATE TABLE IF NOT EXISTS public.appointments (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id       UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    doctor_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    scheduled_at     TIMESTAMPTZ NOT NULL,
    token_number     INTEGER,
    booking_channel  TEXT CHECK (booking_channel IN ('walk_in', 'online', 'phone')),
    status           TEXT NOT NULL DEFAULT 'scheduled'
                         CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled', 'no_show')),
    chief_complaint  TEXT,
    follow_up_date   DATE,
    reminder_sent    BOOLEAN NOT NULL DEFAULT false,
    created_by       UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1.4  visits
CREATE TABLE IF NOT EXISTS public.visits (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id      UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
    patient_id          UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    doctor_id           UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    visit_date          TIMESTAMPTZ NOT NULL DEFAULT now(),
    chief_complaint     TEXT,
    examination_notes   TEXT,
    diagnosis           TEXT,
    status              TEXT NOT NULL DEFAULT 'waiting'
                            CHECK (status IN ('waiting', 'with_doctor', 'prescription_ready', 'medicines_dispensed', 'closed')),
    follow_up_date      DATE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1.5  vitals
CREATE TABLE IF NOT EXISTS public.vitals (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    visit_id              UUID NOT NULL REFERENCES public.visits(id) ON DELETE CASCADE,
    patient_id            UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    bp_systolic           INTEGER,
    bp_diastolic          INTEGER,
    spo2                  NUMERIC(4,1),
    blood_sugar_fasting   NUMERIC(6,1),
    blood_sugar_pp        NUMERIC(6,1),
    weight                NUMERIC(5,1),
    temperature           NUMERIC(4,1),
    pulse                 INTEGER,
    recorded_by           UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    recorded_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1.6  prescriptions
CREATE TABLE IF NOT EXISTS public.prescriptions (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    visit_id         UUID NOT NULL REFERENCES public.visits(id) ON DELETE CASCADE,
    patient_id       UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    doctor_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    -- [{"name":"Arnica 30C","potency":"30C","dosage":"5 pills","frequency":"TDS","duration":"7 days","instructions":"before meals"}]
    medicines        JSONB NOT NULL DEFAULT '[]',
    doctor_notes     TEXT,
    advice           TEXT,
    follow_up_in_days INTEGER,
    pdf_url          TEXT,
    is_draft         BOOLEAN NOT NULL DEFAULT false,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1.7  medicines_master
CREATE TABLE IF NOT EXISTS public.medicines_master (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                 TEXT NOT NULL UNIQUE,
    category             TEXT,   -- constitutional, acute, topical, miasmatic, etc.
    available_potencies  TEXT[] NOT NULL DEFAULT '{}',
    description          TEXT,
    is_active            BOOLEAN NOT NULL DEFAULT true,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1.8  labs
CREATE TABLE IF NOT EXISTS public.labs (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                   TEXT NOT NULL,
    address                TEXT,
    phone                  TEXT,
    commission_percentage  NUMERIC(5,2) NOT NULL DEFAULT 0
                               CHECK (commission_percentage >= 0 AND commission_percentage <= 100),
    is_active              BOOLEAN NOT NULL DEFAULT true,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1.9  lab_reports
CREATE TABLE IF NOT EXISTS public.lab_reports (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    visit_id             UUID REFERENCES public.visits(id) ON DELETE SET NULL,
    patient_id           UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    lab_id               UUID REFERENCES public.labs(id) ON DELETE SET NULL,
    test_name            TEXT NOT NULL,
    report_date          DATE,
    file_url             TEXT,  -- Supabase Storage URL
    file_type            TEXT CHECK (file_type IN ('pdf', 'image')),
    uploaded_by          UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    notes                TEXT,
    commission_eligible  BOOLEAN NOT NULL DEFAULT false,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1.10  commissions
CREATE TABLE IF NOT EXISTS public.commissions (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lab_report_id         UUID NOT NULL REFERENCES public.lab_reports(id) ON DELETE RESTRICT,
    lab_id                UUID NOT NULL REFERENCES public.labs(id) ON DELETE RESTRICT,
    doctor_id             UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    commission_percentage NUMERIC(5,2) NOT NULL
                              CHECK (commission_percentage >= 0 AND commission_percentage <= 100),
    commission_amount     NUMERIC(10,2),
    month_year            TEXT NOT NULL CHECK (month_year ~ '^\d{4}-\d{2}$'),  -- format: '2025-03'
    status                TEXT NOT NULL DEFAULT 'pending'
                              CHECK (status IN ('pending', 'paid', 'cancelled')),
    notes                 TEXT,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1.11  patient_media
CREATE TABLE IF NOT EXISTS public.patient_media (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id     UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    visit_id       UUID REFERENCES public.visits(id) ON DELETE SET NULL,
    media_type     TEXT CHECK (media_type IN ('photo', 'document', 'scan')),
    category       TEXT,   -- skin_condition, report, xray, general
    file_url       TEXT NOT NULL,
    thumbnail_url  TEXT,
    description    TEXT,
    body_part      TEXT,   -- for skin cases
    uploaded_by    UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- 2. UPDATED_AT trigger helper
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Attach to tables that have updated_at
CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_patients_updated_at
    BEFORE UPDATE ON public.patients
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_visits_updated_at
    BEFORE UPDATE ON public.visits
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_prescriptions_updated_at
    BEFORE UPDATE ON public.prescriptions
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- 3. Auto-create profile on auth.users insert
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, phone, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
        NEW.phone,
        COALESCE(NEW.raw_user_meta_data->>'role', 'patient')
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ---------------------------------------------------------------------------
-- 4. INDEXES
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_patients_phone
    ON public.patients (phone);

CREATE INDEX IF NOT EXISTS idx_patients_name
    ON public.patients USING gin (to_tsvector('english', full_name));

CREATE INDEX IF NOT EXISTS idx_patients_profile_id
    ON public.patients (profile_id);

CREATE INDEX IF NOT EXISTS idx_appointments_scheduled
    ON public.appointments (scheduled_at, doctor_id);

CREATE INDEX IF NOT EXISTS idx_appointments_patient
    ON public.appointments (patient_id);

CREATE INDEX IF NOT EXISTS idx_appointments_status
    ON public.appointments (status);

CREATE INDEX IF NOT EXISTS idx_visits_patient
    ON public.visits (patient_id, visit_date DESC);

CREATE INDEX IF NOT EXISTS idx_visits_appointment
    ON public.visits (appointment_id);

CREATE INDEX IF NOT EXISTS idx_vitals_visit
    ON public.vitals (visit_id);

CREATE INDEX IF NOT EXISTS idx_vitals_patient
    ON public.vitals (patient_id);

CREATE INDEX IF NOT EXISTS idx_prescriptions_visit
    ON public.prescriptions (visit_id);

CREATE INDEX IF NOT EXISTS idx_prescriptions_patient
    ON public.prescriptions (patient_id);

CREATE INDEX IF NOT EXISTS idx_lab_reports_patient
    ON public.lab_reports (patient_id);

CREATE INDEX IF NOT EXISTS idx_lab_reports_visit
    ON public.lab_reports (visit_id);

CREATE INDEX IF NOT EXISTS idx_commissions_month
    ON public.commissions (month_year, doctor_id);

CREATE INDEX IF NOT EXISTS idx_commissions_lab_report
    ON public.commissions (lab_report_id);

CREATE INDEX IF NOT EXISTS idx_patient_media_patient
    ON public.patient_media (patient_id);

-- ---------------------------------------------------------------------------
-- 5. ROW LEVEL SECURITY
-- ---------------------------------------------------------------------------

-- Helper: get the role of the calling user (avoids repeated sub-selects)
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

-- ── 5.1  profiles ──────────────────────────────────────────────────────────
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Any authenticated user can read all profiles (for doctor/staff lookup)
CREATE POLICY "profiles_select_all_authenticated"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (true);

-- A user can update only their own profile
CREATE POLICY "profiles_update_own"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- A user can insert their own profile row (from the trigger / onboarding)
CREATE POLICY "profiles_insert_own"
    ON public.profiles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- ── 5.2  patients ──────────────────────────────────────────────────────────
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;

-- Doctor / staff see all patients; a patient sees only their own record
CREATE POLICY "patients_select"
    ON public.patients FOR SELECT
    TO authenticated
    USING (
        public.current_user_role() IN ('doctor', 'staff')
        OR profile_id = auth.uid()
    );

-- Only staff and doctor can create patients
CREATE POLICY "patients_insert"
    ON public.patients FOR INSERT
    TO authenticated
    WITH CHECK (public.current_user_role() IN ('doctor', 'staff'));

-- Only staff and doctor can update patients
CREATE POLICY "patients_update"
    ON public.patients FOR UPDATE
    TO authenticated
    USING (public.current_user_role() IN ('doctor', 'staff'))
    WITH CHECK (public.current_user_role() IN ('doctor', 'staff'));

-- ── 5.3  appointments ──────────────────────────────────────────────────────
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

-- Doctor and staff see all; patient sees only their own
CREATE POLICY "appointments_select"
    ON public.appointments FOR SELECT
    TO authenticated
    USING (
        public.current_user_role() IN ('doctor', 'staff')
        OR patient_id IN (
            SELECT id FROM public.patients WHERE profile_id = auth.uid()
        )
    );

-- Any authenticated role can book an appointment
CREATE POLICY "appointments_insert"
    ON public.appointments FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Only doctor and staff can modify appointments
CREATE POLICY "appointments_update"
    ON public.appointments FOR UPDATE
    TO authenticated
    USING (public.current_user_role() IN ('doctor', 'staff'))
    WITH CHECK (public.current_user_role() IN ('doctor', 'staff'));

-- ── 5.4  visits ────────────────────────────────────────────────────────────
ALTER TABLE public.visits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "visits_select"
    ON public.visits FOR SELECT
    TO authenticated
    USING (
        public.current_user_role() IN ('doctor', 'staff')
        OR patient_id IN (
            SELECT id FROM public.patients WHERE profile_id = auth.uid()
        )
    );

CREATE POLICY "visits_insert"
    ON public.visits FOR INSERT
    TO authenticated
    WITH CHECK (public.current_user_role() IN ('doctor', 'staff'));

CREATE POLICY "visits_update"
    ON public.visits FOR UPDATE
    TO authenticated
    USING (public.current_user_role() IN ('doctor', 'staff'))
    WITH CHECK (public.current_user_role() IN ('doctor', 'staff'));

-- ── 5.5  vitals ────────────────────────────────────────────────────────────
ALTER TABLE public.vitals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "vitals_select"
    ON public.vitals FOR SELECT
    TO authenticated
    USING (
        public.current_user_role() IN ('doctor', 'staff')
        OR patient_id IN (
            SELECT id FROM public.patients WHERE profile_id = auth.uid()
        )
    );

CREATE POLICY "vitals_insert"
    ON public.vitals FOR INSERT
    TO authenticated
    WITH CHECK (public.current_user_role() IN ('doctor', 'staff'));

CREATE POLICY "vitals_update"
    ON public.vitals FOR UPDATE
    TO authenticated
    USING (public.current_user_role() IN ('doctor', 'staff'))
    WITH CHECK (public.current_user_role() IN ('doctor', 'staff'));

-- ── 5.6  prescriptions ─────────────────────────────────────────────────────
ALTER TABLE public.prescriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "prescriptions_select"
    ON public.prescriptions FOR SELECT
    TO authenticated
    USING (
        public.current_user_role() IN ('doctor', 'staff')
        OR patient_id IN (
            SELECT id FROM public.patients WHERE profile_id = auth.uid()
        )
    );

-- Only doctor can create / edit prescriptions
CREATE POLICY "prescriptions_insert"
    ON public.prescriptions FOR INSERT
    TO authenticated
    WITH CHECK (public.current_user_role() = 'doctor');

CREATE POLICY "prescriptions_update"
    ON public.prescriptions FOR UPDATE
    TO authenticated
    USING (public.current_user_role() = 'doctor')
    WITH CHECK (public.current_user_role() = 'doctor');

-- ── 5.7  medicines_master ──────────────────────────────────────────────────
ALTER TABLE public.medicines_master ENABLE ROW LEVEL SECURITY;

CREATE POLICY "medicines_master_select"
    ON public.medicines_master FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "medicines_master_insert"
    ON public.medicines_master FOR INSERT
    TO authenticated
    WITH CHECK (public.current_user_role() = 'doctor');

CREATE POLICY "medicines_master_update"
    ON public.medicines_master FOR UPDATE
    TO authenticated
    USING (public.current_user_role() = 'doctor')
    WITH CHECK (public.current_user_role() = 'doctor');

CREATE POLICY "medicines_master_delete"
    ON public.medicines_master FOR DELETE
    TO authenticated
    USING (public.current_user_role() = 'doctor');

-- ── 5.8  labs ──────────────────────────────────────────────────────────────
ALTER TABLE public.labs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "labs_select"
    ON public.labs FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "labs_insert"
    ON public.labs FOR INSERT
    TO authenticated
    WITH CHECK (public.current_user_role() = 'doctor');

CREATE POLICY "labs_update"
    ON public.labs FOR UPDATE
    TO authenticated
    USING (public.current_user_role() = 'doctor')
    WITH CHECK (public.current_user_role() = 'doctor');

CREATE POLICY "labs_delete"
    ON public.labs FOR DELETE
    TO authenticated
    USING (public.current_user_role() = 'doctor');

-- ── 5.9  lab_reports ───────────────────────────────────────────────────────
ALTER TABLE public.lab_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "lab_reports_select"
    ON public.lab_reports FOR SELECT
    TO authenticated
    USING (
        public.current_user_role() IN ('doctor', 'staff')
        OR patient_id IN (
            SELECT id FROM public.patients WHERE profile_id = auth.uid()
        )
    );

CREATE POLICY "lab_reports_insert"
    ON public.lab_reports FOR INSERT
    TO authenticated
    WITH CHECK (public.current_user_role() IN ('doctor', 'staff'));

CREATE POLICY "lab_reports_update"
    ON public.lab_reports FOR UPDATE
    TO authenticated
    USING (public.current_user_role() IN ('doctor', 'staff'))
    WITH CHECK (public.current_user_role() IN ('doctor', 'staff'));

-- ── 5.10  commissions ──────────────────────────────────────────────────────
ALTER TABLE public.commissions ENABLE ROW LEVEL SECURITY;

-- Doctor only: full access
CREATE POLICY "commissions_select"
    ON public.commissions FOR SELECT
    TO authenticated
    USING (public.current_user_role() = 'doctor');

CREATE POLICY "commissions_insert"
    ON public.commissions FOR INSERT
    TO authenticated
    WITH CHECK (public.current_user_role() = 'doctor');

CREATE POLICY "commissions_update"
    ON public.commissions FOR UPDATE
    TO authenticated
    USING (public.current_user_role() = 'doctor')
    WITH CHECK (public.current_user_role() = 'doctor');

CREATE POLICY "commissions_delete"
    ON public.commissions FOR DELETE
    TO authenticated
    USING (public.current_user_role() = 'doctor');

-- ── 5.11  patient_media ────────────────────────────────────────────────────
ALTER TABLE public.patient_media ENABLE ROW LEVEL SECURITY;

CREATE POLICY "patient_media_select"
    ON public.patient_media FOR SELECT
    TO authenticated
    USING (
        public.current_user_role() IN ('doctor', 'staff')
        OR patient_id IN (
            SELECT id FROM public.patients WHERE profile_id = auth.uid()
        )
    );

CREATE POLICY "patient_media_insert"
    ON public.patient_media FOR INSERT
    TO authenticated
    WITH CHECK (public.current_user_role() IN ('doctor', 'staff'));

CREATE POLICY "patient_media_update"
    ON public.patient_media FOR UPDATE
    TO authenticated
    USING (public.current_user_role() IN ('doctor', 'staff'))
    WITH CHECK (public.current_user_role() IN ('doctor', 'staff'));

-- ---------------------------------------------------------------------------
-- 6. REALTIME
-- (Enable publication for live updates on staff/doctor screens)
-- ---------------------------------------------------------------------------
-- supabase_realtime publication is created by Supabase automatically.
-- We add specific tables to it.
ALTER PUBLICATION supabase_realtime ADD TABLE public.visits;
ALTER PUBLICATION supabase_realtime ADD TABLE public.prescriptions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.vitals;

-- ---------------------------------------------------------------------------
-- 7. STORAGE BUCKETS
-- (These SQL statements work in Supabase's storage schema)
-- ---------------------------------------------------------------------------

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
    (
        'patient-media',
        'patient-media',
        false,
        10485760,  -- 10 MB
        ARRAY['image/jpeg','image/png','image/webp','image/gif','application/pdf']
    ),
    (
        'prescription-pdfs',
        'prescription-pdfs',
        false,
        5242880,   -- 5 MB
        ARRAY['application/pdf']
    )
ON CONFLICT (id) DO NOTHING;

-- Storage RLS: patient-media bucket
CREATE POLICY "patient_media_bucket_select"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'patient-media'
        AND (
            public.current_user_role() IN ('doctor', 'staff')
            OR (storage.foldername(name))[1] = auth.uid()::text
        )
    );

CREATE POLICY "patient_media_bucket_insert"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'patient-media'
        AND public.current_user_role() IN ('doctor', 'staff')
    );

CREATE POLICY "patient_media_bucket_delete"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'patient-media'
        AND public.current_user_role() IN ('doctor', 'staff')
    );

-- Storage RLS: prescription-pdfs bucket
CREATE POLICY "prescription_pdfs_bucket_select"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'prescription-pdfs'
        AND (
            public.current_user_role() IN ('doctor', 'staff')
            OR (storage.foldername(name))[1] = auth.uid()::text
        )
    );

CREATE POLICY "prescription_pdfs_bucket_insert"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'prescription-pdfs'
        AND public.current_user_role() = 'doctor'
    );

CREATE POLICY "prescription_pdfs_bucket_delete"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'prescription-pdfs'
        AND public.current_user_role() = 'doctor'
    );

-- ---------------------------------------------------------------------------
-- 8. SEED – medicines_master (50 common homeopathic remedies)
-- ---------------------------------------------------------------------------
INSERT INTO public.medicines_master (name, category, available_potencies, description) VALUES

-- Constitutional / Polychrest remedies
('Arnica Montana',        'constitutional', ARRAY['6C','12C','30C','200C','1M'],       'Trauma, bruising, muscle soreness, shock.'),
('Belladonna',            'acute',          ARRAY['6C','12C','30C','200C'],             'Sudden fever, inflammation, throbbing pain, red face.'),
('Nux Vomica',            'constitutional', ARRAY['6C','12C','30C','200C','1M'],       'Digestive complaints, irritability, over-indulgence.'),
('Sulphur',               'constitutional', ARRAY['6C','12C','30C','200C','1M','10M'], 'Skin conditions, burning sensation, chronic disease.'),
('Calcarea Carbonica',    'constitutional', ARRAY['6C','30C','200C','1M'],             'Obesity, slow metabolism, anxiety in children.'),
('Lycopodium',            'constitutional', ARRAY['6C','30C','200C','1M'],             'Digestive weakness, liver, lack of confidence.'),
('Pulsatilla',            'constitutional', ARRAY['6C','12C','30C','200C','1M'],       'Mild, yielding disposition; hormonal issues; thick yellow discharge.'),
('Sepia',                 'constitutional', ARRAY['6C','30C','200C','1M'],             'Female hormonal complaints, indifference, prolapse.'),
('Phosphorus',            'constitutional', ARRAY['6C','30C','200C','1M'],             'Respiratory issues, haemorrhage, anxiety, tall thin patients.'),
('Bryonia',               'acute',          ARRAY['6C','12C','30C','200C'],             'Dryness, worse movement, slow onset illness, constipation.'),

-- Musculoskeletal / Injury
('Rhus Toxicodendron',    'acute',          ARRAY['6C','12C','30C','200C'],             'Arthritis, stiffness better with movement, sprains.'),
('Ruta Graveolens',       'acute',          ARRAY['6C','12C','30C','200C'],             'Tendon and periosteum injuries, eye strain.'),
('Symphytum',             'acute',          ARRAY['6C','30C','200C'],                   'Bone fractures, eye injuries.'),
('Hypericum',             'acute',          ARRAY['6C','30C','200C'],                   'Nerve injuries, sharp shooting pain.'),
('Ledum Palustre',        'acute',          ARRAY['6C','30C','200C'],                   'Puncture wounds, insect stings, cold joints.'),

-- Respiratory / Allergic
('Apis Mellifica',        'acute',          ARRAY['6C','12C','30C','200C'],             'Allergic reactions, oedema, stinging pain, urticaria.'),
('Aconite',               'acute',          ARRAY['6C','12C','30C','200C'],             'Sudden onset fever from cold dry wind, anxiety, fear.'),
('Gelsemium',             'acute',          ARRAY['6C','12C','30C','200C'],             'Influenza, weakness, trembling, anticipatory anxiety.'),
('Drosera',               'acute',          ARRAY['6C','30C','200C'],                   'Spasmodic cough, whooping cough, laryngitis.'),
('Spongia Tosta',         'acute',          ARRAY['6C','30C','200C'],                   'Dry barking cough, croup, cardiac complaints.'),

-- Emotional / Nervous
('Ignatia',               'acute',          ARRAY['6C','30C','200C','1M'],             'Grief, emotional shock, contradiction, hysteria.'),
('Staphysagria',          'constitutional', ARRAY['6C','30C','200C'],                   'Suppressed anger, post-surgical wounds, cystitis.'),
('Natrum Muriaticum',     'constitutional', ARRAY['6C','30C','200C','1M'],             'Grief, reserved, headaches, cold sores, anaemia.'),
('Aurum Metallicum',      'constitutional', ARRAY['30C','200C','1M'],                   'Depression, suicidal tendency, heart complaints.'),
('Causticum',             'constitutional', ARRAY['6C','30C','200C'],                   'Paralysis, chronic cough, urinary incontinence, burns.'),

-- Skin conditions
('Thuja Occidentalis',    'constitutional', ARRAY['6C','30C','200C','1M'],             'Warts, oily skin, fixed ideas, vaccination ill-effects.'),
('Graphites',             'constitutional', ARRAY['6C','30C','200C'],                   'Eczema with honey-like discharge, obesity, constipation.'),
('Petroleum',             'acute',          ARRAY['6C','30C','200C'],                   'Deep skin cracks, eczema worse winter, motion sickness.'),
('Mezereum',              'acute',          ARRAY['6C','30C','200C'],                   'Violent itching, herpes zoster, bone pains.'),
('Antimonium Crudum',     'acute',          ARRAY['6C','30C','200C'],                   'Thick white coated tongue, skin eruptions, corns.'),

-- Digestive
('Carbo Vegetabilis',     'acute',          ARRAY['6C','30C','200C'],                   'Bloating, flatulence, collapse, venous stasis.'),
('Colocynthis',           'acute',          ARRAY['6C','30C','200C'],                   'Colicky pain better with pressure, sciatica.'),
('Veratrum Album',        'acute',          ARRAY['6C','30C','200C'],                   'Profuse vomiting and diarrhoea, cold sweat, collapse.'),
('Ipecacuanha',           'acute',          ARRAY['6C','30C','200C'],                   'Persistent nausea, haemorrhage, spasmodic cough.'),
('Chamomilla',            'acute',          ARRAY['6C','30C','200C'],                   'Extreme irritability, teething, colic in children.'),

-- Infections / Fevers
('Lachesis',              'constitutional', ARRAY['12C','30C','200C','1M'],            'Left-sided complaints, menopause, jealousy, sepsis.'),
('Mercurius Solubilis',   'acute',          ARRAY['6C','12C','30C','200C'],             'Infections with offensive discharges, ulcers, night sweats.'),
('Hepar Sulphuris',       'acute',          ARRAY['6C','30C','200C'],                   'Suppuration, abscesses, hypersensitivity to pain.'),
('Pyrogenium',            'acute',          ARRAY['30C','200C','1M'],                   'Septic states, high fever with slow pulse ratio.'),
('Baptisia Tinctoria',    'acute',          ARRAY['6C','30C','200C'],                   'Typhoid-like states, sepsis, dark offensive discharges.'),

-- Female / Hormonal
('Cimicifuga',            'constitutional', ARRAY['6C','30C','200C'],                   'Menopausal complaints, dysmenorrhoea, muscle pain.'),
('Folliculinum',          'constitutional', ARRAY['6C','30C','200C'],                   'Oestrogen dominance, PMS, hormonal dysregulation.'),
('Sabina',                'acute',          ARRAY['6C','30C','200C'],                   'Heavy periods, threatened miscarriage, gout.'),

-- Urinary / Renal
('Berberis Vulgaris',     'acute',          ARRAY['6C','30C','200C'],                   'Kidney stones, renal colic, radiating pain.'),
('Cantharis',             'acute',          ARRAY['6C','30C','200C'],                   'Burning urination, cystitis, blistering burns.'),
('Solidago',              'acute',          ARRAY['6C','30C','200C'],                   'Kidney weakness, cloudy urine, oedema.'),

-- Cardiovascular / Circulation
('Crataegus',             'constitutional', ARRAY['6C','30C','200C'],                   'Heart tonic, hypertension, arterio-sclerosis.'),
('Digitalis',             'acute',          ARRAY['6C','30C','200C'],                   'Heart failure, slow irregular pulse, oedema.'),

-- Paediatric / Growth
('Silica',                'constitutional', ARRAY['6C','30C','200C','1M'],             'Lack of stamina, recurrent infections, weak bones, shyness.'),
('Baryta Carbonica',      'constitutional', ARRAY['6C','30C','200C'],                   'Developmental delay, enlarged tonsils, timidity, senility.')

ON CONFLICT (name) DO NOTHING;

-- =============================================================================
-- END OF MIGRATION 001_initial_schema.sql
-- =============================================================================

