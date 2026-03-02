// Supabase Edge Function: send-notification
// Sends SMS via MSG91 and optionally creates an in-app notification row.
//
// Expected request body:
// {
//   "recipient_id": "uuid",
//   "recipient_phone": "+919876543210",
//   "title": "Appointment Reminder",
//   "body": "Your appointment is at 2:30 PM today.",
//   "type": "appointment",
//   "reference_id": "optional-uuid"
// }

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const MSG91_AUTH_KEY = Deno.env.get("MSG91_AUTH_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

serve(async (req: Request) => {
  try {
    const body = await req.json();
    const {
      recipient_id,
      recipient_phone,
      title,
      body: messageBody,
      type = "general",
      reference_id,
    } = body;

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // 1. Insert in-app notification
    if (recipient_id) {
      await supabase.from("notifications").insert({
        recipient_id,
        title,
        body: messageBody,
        type,
        reference_id,
      });
    }

    // 2. Send SMS via MSG91
    if (recipient_phone && MSG91_AUTH_KEY) {
      const smsPayload = {
        sender: "HMCLNC",
        route: "4",
        country: "91",
        sms: [
          {
            message: `${title}: ${messageBody}`,
            to: [recipient_phone.replace("+91", "")],
          },
        ],
      };

      const smsResponse = await fetch(
        "https://api.msg91.com/api/v2/sendsms",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            authkey: MSG91_AUTH_KEY,
          },
          body: JSON.stringify(smsPayload),
        }
      );

      const smsResult = await smsResponse.json();
      console.log("SMS result:", smsResult);
    }

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("send-notification error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

