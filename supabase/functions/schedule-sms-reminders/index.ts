import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    // Create Supabase client with service role key for full database access
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey)

    console.log('🔔 Starting SMS reminder scheduler...')

    // Get current time
    const now = new Date()
    const currentHour = now.getHours()
    const currentMinute = now.getMinutes()
    const currentTime = `${currentHour.toString().padStart(2, '0')}:${currentMinute.toString().padStart(2, '0')}`

    console.log(`⏰ Current time: ${currentTime}`)

    // Get users who have SMS reminders enabled and phone verified
    const { data: users, error: usersError } = await supabase
      .from('user_profiles')
      .select(`
        id, 
        name, 
        phone_number, 
        phone_verified,
        sms_reminders_enabled,
        sms_workout_reminders,
        sms_motivation_messages,
        sms_progress_reminders
      `)
      .eq('phone_verified', true)
      .eq('sms_reminders_enabled', true)
      .not('phone_number', 'is', null)

    if (usersError) {
      console.error('Error fetching users:', usersError)
      return new Response(JSON.stringify({ error: 'Failed to fetch users' }), { status: 500 })
    }

    console.log(`📱 Found ${users?.length || 0} users with SMS enabled`)

    if (!users || users.length === 0) {
      return new Response(JSON.stringify({ message: 'No users found with SMS reminders enabled' }), { status: 200 })
    }

    // Get users' notification preferences
    const { data: notificationSettings } = await supabase
      .from('user_profiles')
      .select('id')
      .eq('phone_verified', true)

    // Load saved notification preferences for each user (stored in localStorage equivalent)
    // For now, we'll use a simpler approach and check based on time and day

    let messagesSent = 0
    const errors = []

    for (const user of users) {
      try {
        // Skip if user doesn't have verified phone
        if (!user.phone_verified || !user.phone_number) {
          continue
        }

        let shouldSendMessage = false
        let messageType = ''
        let message = ''

        // Check if it's time for workout reminders (defaulting to 6 PM if no specific time set)
        const workoutHour = 18 // 6 PM default
        if (currentHour === workoutHour && currentMinute === 0 && user.sms_workout_reminders) {
          shouldSendMessage = true
          messageType = 'workout_reminder'
          message = `🏋️ Hi ${user.name || 'there'}! It's time for your workout! 💪 Open Gymcyclopedia and crush those fitness goals today! 🔥`
        }
        
        // Morning motivation messages (9 AM)
        else if (currentHour === 9 && currentMinute === 0 && user.sms_motivation_messages) {
          const motivationMessages = [
            `🌅 Good morning ${user.name || 'champion'}! Today is a new opportunity to become stronger! 💪`,
            `☀️ Rise and grind ${user.name || 'warrior'}! Your fitness journey continues today! 🔥`,
            `🌟 Hello ${user.name || 'superstar'}! Remember: every workout brings you closer to your goals! 🎯`,
            `⚡ Morning ${user.name || 'athlete'}! Your body is capable of amazing things - show it what you've got! 💯`,
            `🚀 Hey ${user.name || 'champion'}! Success isn't given, it's earned in the gym! Let's go! 🏆`
          ]
          shouldSendMessage = true
          messageType = 'motivation'
          message = motivationMessages[Math.floor(Math.random() * motivationMessages.length)]
        }
        
        // Weekly progress reminders (Sunday at 7 PM)
        else if (now.getDay() === 0 && currentHour === 19 && currentMinute === 0 && user.sms_progress_reminders) {
          shouldSendMessage = true
          messageType = 'progress'
          message = `📊 Weekly check-in time, ${user.name || 'champion'}! How did your fitness week go? Track your progress in Gymcyclopedia! 📈`
        }

        if (shouldSendMessage) {
          console.log(`📲 Sending ${messageType} to ${user.phone_number}`)
          
          // Call the send-sms function
          const smsResponse = await fetch(`${supabaseUrl}/functions/v1/send-sms`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${supabaseServiceRoleKey}`,
            },
            body: JSON.stringify({
              phone_number: user.phone_number,
              message: message,
              message_type: messageType
            })
          })

          if (smsResponse.ok) {
            messagesSent++
            console.log(`✅ SMS sent successfully to ${user.phone_number}`)
          } else {
            const errorText = await smsResponse.text()
            console.error(`❌ Failed to send SMS to ${user.phone_number}:`, errorText)
            errors.push(`Failed to send to ${user.phone_number}: ${errorText}`)
          }
        }

      } catch (userError) {
        console.error(`Error processing user ${user.id}:`, userError)
        errors.push(`Error processing user ${user.id}: ${userError.message}`)
      }
    }

    console.log(`📊 SMS Scheduler completed. Messages sent: ${messagesSent}, Errors: ${errors.length}`)

    return new Response(JSON.stringify({ 
      success: true,
      messagesSent,
      errors: errors.length > 0 ? errors : undefined,
      timestamp: now.toISOString()
    }), { 
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('Error in SMS scheduler:', error)
    return new Response(JSON.stringify({ 
      error: 'Internal server error', 
      details: error.message 
    }), { 
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }
}) 