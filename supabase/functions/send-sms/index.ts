import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface SMSRequest {
  phone_number: string
  message: string
  message_type: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Parse request
    const { phone_number, message, message_type }: SMSRequest = await req.json()
    
    // Validate required fields
    if (!phone_number || !message) {
      return new Response(
        JSON.stringify({ error: 'Phone number and message are required' }), 
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get Twilio credentials from environment variables
    const twilioAccountSid = Deno.env.get('TWILIO_ACCOUNT_SID')
    const twilioAuthToken = Deno.env.get('TWILIO_AUTH_TOKEN')
    const twilioPhoneNumber = Deno.env.get('TWILIO_PHONE_NUMBER')

    if (!twilioAccountSid || !twilioAuthToken || !twilioPhoneNumber) {
      console.error('Missing Twilio configuration')
      return new Response(
        JSON.stringify({ error: 'SMS service not configured' }), 
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create Supabase client for logging
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey)

    // Get user ID from authorization header
    const authHeader = req.headers.get('authorization')
    let userId = null
    
    if (authHeader) {
      const jwt = authHeader.replace('Bearer ', '')
      const { data: { user } } = await supabase.auth.getUser(jwt)
      userId = user?.id
    }

    try {
      // Send SMS using Twilio API
      const auth = btoa(`${twilioAccountSid}:${twilioAuthToken}`)
      
      const response = await fetch(
        `https://api.twilio.com/2010-04-01/Accounts/${twilioAccountSid}/Messages.json`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Basic ${auth}`,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: new URLSearchParams({
            From: twilioPhoneNumber,
            To: phone_number,
            Body: message,
          }),
        }
      )

      const twilioResult = await response.json()

      if (!response.ok) {
        console.error('Twilio API error:', twilioResult)
        
        // Log failed SMS attempt
        if (userId) {
          await supabase.from('sms_logs').insert({
            user_id: userId,
            phone_number,
            message_type,
            message_content: message,
            status: 'failed',
            error_message: twilioResult.message || 'Unknown Twilio error'
          })
        }

        return new Response(
          JSON.stringify({ error: 'Failed to send SMS', details: twilioResult.message }), 
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Log successful SMS
      if (userId) {
        await supabase.from('sms_logs').insert({
          user_id: userId,
          phone_number,
          message_type,
          message_content: message,
          status: 'sent',
          cost_cents: Math.round((twilioResult.price || 0) * 100), // Convert to cents
          provider: 'twilio'
        })
      }

      return new Response(
        JSON.stringify({ 
          success: true, 
          message_sid: twilioResult.sid,
          status: twilioResult.status 
        }), 
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )

    } catch (twilioError) {
      console.error('Error sending SMS:', twilioError)
      
      // Log failed SMS attempt
      if (userId) {
        await supabase.from('sms_logs').insert({
          user_id: userId,
          phone_number,
          message_type,
          message_content: message,
          status: 'failed',
          error_message: twilioError.message || 'Network error'
        })
      }

      return new Response(
        JSON.stringify({ error: 'Failed to send SMS', details: twilioError.message }), 
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

  } catch (error) {
    console.error('Error in send-sms function:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }), 
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}) 