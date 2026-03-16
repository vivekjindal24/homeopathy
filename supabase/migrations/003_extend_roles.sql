-- =============================================================================
-- 003_extend_roles.sql
-- Homeopathy Clinic – Extend the profiles.role CHECK constraint to include
-- the new roles required by the full 6-role architecture:
--   receptionist, admin, lab_partner
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. profiles — extend role CHECK constraint
-- ---------------------------------------------------------------------------

-- Remove the old constraint that only knew doctor / staff / patient
ALTER TABLE public.profiles
    DROP CONSTRAINT IF EXISTS profiles_role_check;

-- Add the updated constraint with all six roles
ALTER TABLE public.profiles
    ADD CONSTRAINT profiles_role_check
    CHECK (role IN ('doctor', 'staff', 'receptionist', 'admin', 'lab_partner', 'patient'));

-- ---------------------------------------------------------------------------
-- 2. RLS helpers — update current_user_role() usages in existing policies
--    so that receptionist and admin have the same data-access rights as staff
--    for patient records, appointments, vitals, prescriptions, lab reports,
--    and media.
--    (The Dart app enforces finer-grained UI restrictions.)
-- ---------------------------------------------------------------------------

-- Helper view that broadens "clinic staff" to include the new roles.
-- Existing policies use current_user_role() = 'doctor' / 'staff'.
-- We add parallel policies for the new roles rather than replacing the
-- existing ones, to keep the migration idempotent and non-destructive.

-- patients: receptionist / admin can read and write
CREATE POLICY IF NOT EXISTS "patients_receptionist_select"
    ON public.patients FOR SELECT
    TO authenticated
    USING (public.current_user_role() IN ('receptionist', 'admin'));

CREATE POLICY IF NOT EXISTS "patients_receptionist_insert"
    ON public.patients FOR INSERT
    TO authenticated
    WITH CHECK (public.current_user_role() IN ('receptionist', 'admin'));

CREATE POLICY IF NOT EXISTS "patients_receptionist_update"
    ON public.patients FOR UPDATE
    TO authenticated
    USING (public.current_user_role() IN ('receptionist', 'admin'))
    WITH CHECK (public.current_user_role() IN ('receptionist', 'admin'));

-- appointments: receptionist / admin can manage appointments
CREATE POLICY IF NOT EXISTS "appointments_receptionist_select"
    ON public.appointments FOR SELECT
    TO authenticated
    USING (public.current_user_role() IN ('receptionist', 'admin'));

CREATE POLICY IF NOT EXISTS "appointments_receptionist_insert"
    ON public.appointments FOR INSERT
    TO authenticated
    WITH CHECK (public.current_user_role() IN ('receptionist', 'admin'));

CREATE POLICY IF NOT EXISTS "appointments_receptionist_update"
    ON public.appointments FOR UPDATE
    TO authenticated
    USING (public.current_user_role() IN ('receptionist', 'admin'))
    WITH CHECK (public.current_user_role() IN ('receptionist', 'admin'));

-- vitals: receptionist / admin can read vitals (not write)
CREATE POLICY IF NOT EXISTS "vitals_receptionist_select"
    ON public.vitals FOR SELECT
    TO authenticated
    USING (public.current_user_role() IN ('receptionist', 'admin'));

-- prescriptions: receptionist / admin can read prescriptions
CREATE POLICY IF NOT EXISTS "prescriptions_receptionist_select"
    ON public.prescriptions FOR SELECT
    TO authenticated
    USING (public.current_user_role() IN ('receptionist', 'admin'));

-- lab_reports: receptionist / admin can read; lab_partner can read and write
CREATE POLICY IF NOT EXISTS "lab_reports_receptionist_select"
    ON public.lab_reports FOR SELECT
    TO authenticated
    USING (public.current_user_role() IN ('receptionist', 'admin', 'lab_partner'));

CREATE POLICY IF NOT EXISTS "lab_reports_lab_partner_insert"
    ON public.lab_reports FOR INSERT
    TO authenticated
    WITH CHECK (public.current_user_role() = 'lab_partner');

CREATE POLICY IF NOT EXISTS "lab_reports_lab_partner_update"
    ON public.lab_reports FOR UPDATE
    TO authenticated
    USING (public.current_user_role() = 'lab_partner')
    WITH CHECK (public.current_user_role() = 'lab_partner');

-- patient_media: receptionist / admin can read
CREATE POLICY IF NOT EXISTS "patient_media_receptionist_select"
    ON public.patient_media FOR SELECT
    TO authenticated
    USING (public.current_user_role() IN ('receptionist', 'admin'));

-- commissions: admin can manage commissions
CREATE POLICY IF NOT EXISTS "commissions_admin_all"
    ON public.commissions FOR ALL
    TO authenticated
    USING (public.current_user_role() = 'admin')
    WITH CHECK (public.current_user_role() = 'admin');

-- notifications: all authenticated users can see their own (policy already
-- exists in 002); no changes needed for new roles.

-- profiles: admin can read all profiles for user management
CREATE POLICY IF NOT EXISTS "profiles_admin_select"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (public.current_user_role() = 'admin');

-- ---------------------------------------------------------------------------
-- 3. Update handle_new_user trigger to accept new role values
--    The COALESCE default is already 'patient', so no change needed there.
--    This comment documents that the trigger is compatible with new roles.
-- ---------------------------------------------------------------------------

-- =============================================================================
-- END OF MIGRATION 003_extend_roles.sql
-- =============================================================================
