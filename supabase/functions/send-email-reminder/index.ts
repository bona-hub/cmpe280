import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface EmailRequest {
  user_email: string
  user_name: string
  subject: string
  message: string
  message_type: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { user_email, user_name, subject, message, message_type }: EmailRequest = await req.json()
    
    if (!user_email || !message) {
      return new Response(
        JSON.stringify({ error: 'Email and message are required' }), 
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey)

    // Get user ID from email
    const { data: userData } = await supabase
      .from('user_profiles')
      .select('id')
      .eq('email', user_email)
      .single()

    // Create beautiful HTML email template
    const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Gymcyclopedia Reminder</title>
    </head>
    <body style="margin: 0; padding: 0; background-color: #000; color: #fff; font-family: 'Arial', sans-serif;">
      <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
        <!-- Header -->
        <div style="text-align: center; padding: 30px 0; background: linear-gradient(45deg, #007bff, #00d4ff); border-radius: 15px; margin-bottom: 30px;">
          <h1 style="margin: 0; font-size: 28px; font-weight: bold; letter-spacing: 2px;">
            💪 GYMCYCLOPEDIA
          </h1>
          <p style="margin: 10px 0 0 0; font-size: 16px; opacity: 0.9;">
            Your Fitness Journey Continues
          </p>
        </div>

        <!-- Main Content -->
        <div style="background: rgba(255, 255, 255, 0.05); border: 1px solid rgba(255, 255, 255, 0.1); border-radius: 15px; padding: 30px; margin-bottom: 30px;">
          <h2 style="color: #00d4ff; margin-top: 0; font-size: 24px;">
            ${getEmailIcon(message_type)} ${subject}
          </h2>
          
          <p style="font-size: 18px; line-height: 1.6; margin: 20px 0;">
            Hi ${user_name || 'Champion'}! 👋
          </p>
          
          <div style="background: rgba(0, 123, 255, 0.1); border-left: 4px solid #007bff; padding: 20px; margin: 20px 0; border-radius: 8px;">
            <p style="font-size: 16px; line-height: 1.6; margin: 0;">
              ${message}
            </p>
          </div>

          <div style="text-align: center; margin: 30px 0;">
            <a href="http://localhost:8000/workouts.html" 
               style="display: inline-block; background: linear-gradient(45deg, #007bff, #00d4ff); color: white; text-decoration: none; padding: 15px 30px; border-radius: 25px; font-weight: bold; font-size: 16px;">
              🚀 Open Gymcyclopedia
            </a>
          </div>
        </div>

        <!-- Footer -->
        <div style="text-align: center; padding: 20px; opacity: 0.7;">
          <p style="margin: 0; font-size: 14px;">
            Keep crushing your fitness goals! 💪<br>
            You're stronger than yesterday! 🔥
          </p>
          <p style="margin: 10px 0 0 0; font-size: 12px;">
            Don't want these reminders? 
            <a href="#" style="color: #00d4ff; text-decoration: none;">Update your preferences</a>
          </p>
        </div>
      </div>
    </body>
    </html>
    `

    // Send email using Supabase Auth (completely free!)
    const { error: emailError } = await supabase.auth.admin.generateLink({
      type: 'magiclink',
      email: user_email,
      options: {
        redirectTo: 'http://localhost:8000/workouts.html',
        data: {
          custom_email: true,
          subject: subject,
          html_content: htmlContent
        }
      }
    })

    if (emailError) {
      console.error('Email sending error:', emailError)
      return new Response(
        JSON.stringify({ error: 'Failed to send email', details: emailError.message }), 
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Log the email (optional)
    if (userData) {
      await supabase.from('email_logs').insert({
        user_id: userData.id,
        email: user_email,
        message_type,
        subject,
        message_content: message,
        sent_at: new Date().toISOString(),
        status: 'sent'
      }).catch(console.error) // Don't fail if logging fails
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Email reminder sent successfully'
      }), 
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Error in send-email-reminder function:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }), 
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

function getEmailIcon(messageType: string): string {
  switch (messageType) {
    case 'workout_reminder': return '🏋️'
    case 'motivation': return '🌟'
    case 'progress': return '📊'
    case 'achievement': return '🏆'
    default: return '💪'
  }
} 