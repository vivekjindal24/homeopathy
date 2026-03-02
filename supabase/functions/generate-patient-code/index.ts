// Supabase Edge Function: generate-patient-code
// Atomically generates the next patient code (HP-XXXX).
// This is a fallback — the DB trigger handles it automatically.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

serve(async (_req: Request) => {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const { data, error } = await supabase.rpc("nextval", {
      sequence: "patient_code_seq",
    });

    if (error) throw error;

    const code = `HP-${String(data).padStart(4, "0")}`;
    return new Response(
      JSON.stringify({ code }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

