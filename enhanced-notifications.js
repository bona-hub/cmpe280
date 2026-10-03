// ========================================
// ENHANCED WEB PUSH NOTIFICATIONS (FREE!)
// ========================================
// This provides SMS-like functionality using web push notifications

class EnhancedNotifications {
  constructor() {
    this.publicKey = 'YOUR_VAPID_PUBLIC_KEY'; // You'll generate this
    this.swRegistration = null;
    this.isSubscribed = false;
  }

  // Initialize the notification system
  async init() {
    if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
      console.warn('Push notifications not supported');
      return false;
    }

    try {
      // Register service worker
      this.swRegistration = await navigator.serviceWorker.register('/sw-enhanced.js');
      console.log('✅ Service Worker registered');

      // Check if already subscribed
      const subscription = await this.swRegistration.pushManager.getSubscription();
      this.isSubscribed = !(subscription === null);

      return true;
    } catch (error) {
      console.error('Failed to initialize notifications:', error);
      return false;
    }
  }

  // Request permission and subscribe to push notifications
  async subscribe() {
    try {
      const permission = await Notification.requestPermission();
      if (permission !== 'granted') {
        throw new Error('Notification permission denied');
      }

      // Subscribe to push notifications
      const subscription = await this.swRegistration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.urlBase64ToUint8Array(this.publicKey)
      });

      this.isSubscribed = true;

      // Send subscription to your server (optional)
      await this.sendSubscriptionToServer(subscription);

      return subscription;
    } catch (error) {
      console.error('Failed to subscribe to notifications:', error);
      throw error;
    }
  }

  // Schedule workout reminder
  scheduleWorkoutReminder(time = '18:00', message = null) {
    const reminderMessage = message || `🏋️ Time to workout! Your gains are waiting! 💪`;
    
    this.scheduleNotification({
      title: '💪 Workout Time!',
      body: reminderMessage,
      icon: '/icon-192.png',
      badge: '/badge-72.png',
      tag: 'workout-reminder',
      time: time,
      actions: [
        {
          action: 'start-workout',
          title: '🚀 Start Workout'
        },
        {
          action: 'snooze',
          title: '⏰ Remind me in 30min'
        }
      ]
    });
  }

  // Schedule motivation message
  scheduleMotivationMessage() {
    const motivationMessages = [
      "🌟 Every rep counts! You're building a stronger you!",
      "💪 Champions aren't made in comfort zones!",
      "🔥 Your only competition is yesterday's you!",
      "⚡ Push through! Greatness is on the other side!",
      "🏆 Success isn't given, it's earned in the gym!"
    ];

    const randomMessage = motivationMessages[Math.floor(Math.random() * motivationMessages.length)];

    this.scheduleNotification({
      title: '🌟 Daily Motivation',
      body: randomMessage,
      icon: '/icon-192.png',
      tag: 'daily-motivation',
      time: '09:00'
    });
  }

  // Schedule progress reminder
  scheduleProgressReminder() {
    this.scheduleNotification({
      title: '📊 Progress Check-in',
      body: "How's your fitness journey going? Track your progress in Gymcyclopedia! 📈",
      icon: '/icon-192.png',
      tag: 'progress-reminder',
      time: '19:00',
      day: 'sunday'
    });
  }

  // Generic notification scheduler
  scheduleNotification(options) {
    const now = new Date();
    const [hours, minutes] = options.time.split(':');
    
    let scheduledTime = new Date();
    scheduledTime.setHours(parseInt(hours), parseInt(minutes), 0, 0);

    // If time has passed today, schedule for tomorrow
    if (scheduledTime <= now) {
      scheduledTime.setDate(scheduledTime.getDate() + 1);
    }

    // If specific day is required (like Sunday for progress)
    if (options.day) {
      const dayMap = {
        'sunday': 0, 'monday': 1, 'tuesday': 2, 'wednesday': 3,
        'thursday': 4, 'friday': 5, 'saturday': 6
      };
      
      const targetDay = dayMap[options.day.toLowerCase()];
      const currentDay = now.getDay();
      
      let daysUntil = targetDay - currentDay;
      if (daysUntil < 0) daysUntil += 7; // Next week
      
      scheduledTime.setDate(now.getDate() + daysUntil);
    }

    const delay = scheduledTime.getTime() - now.getTime();

    setTimeout(() => {
      this.showNotification(options);
      
      // Reschedule for next occurrence
      if (options.day) {
        // Weekly recurring
        setTimeout(() => this.scheduleNotification(options), 7 * 24 * 60 * 60 * 1000);
      } else {
        // Daily recurring
        setTimeout(() => this.scheduleNotification(options), 24 * 60 * 60 * 1000);
      }
    }, delay);

    console.log(`⏰ Notification "${options.title}" scheduled for ${scheduledTime.toLocaleString()}`);
  }

  // Show immediate notification
  async showNotification(options) {
    if (!this.swRegistration) {
      console.warn('Service worker not registered');
      return;
    }

    const notificationOptions = {
      body: options.body,
      icon: options.icon || '/icon-192.png',
      badge: options.badge || '/badge-72.png',
      tag: options.tag || 'gymcyclopedia-notification',
      requireInteraction: true, // Keeps notification visible until user interacts
      actions: options.actions || [
        {
          action: 'open-app',
          title: '🚀 Open Gymcyclopedia'
        }
      ],
      data: {
        url: '/workouts.html',
        timestamp: Date.now()
      }
    };

    await this.swRegistration.showNotification(options.title, notificationOptions);
    console.log('✅ Notification shown:', options.title);
  }

  // Send test notification
  async sendTestNotification() {
    await this.showNotification({
      title: '🧪 Test Notification',
      body: 'Your enhanced notifications are working perfectly! 🎉',
      tag: 'test-notification',
      actions: [
        {
          action: 'celebrate',
          title: '🎉 Awesome!'
        }
      ]
    });
  }

  // Utility function to convert VAPID key
  urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4);
    const base64 = (base64String + padding)
      .replace(/-/g, '+')
      .replace(/_/g, '/');

    const rawData = window.atob(base64);
    const outputArray = new Uint8Array(rawData.length);

    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i);
    }
    return outputArray;
  }

  // Send subscription to server (for future server-side notifications)
  async sendSubscriptionToServer(subscription) {
    try {
      // You can store this subscription in your database for server-side push notifications
      console.log('💾 Subscription to store:', JSON.stringify(subscription));
      
      // Example: Save to Supabase (uncomment when ready)
      /*
      const { error } = await supabase.from('push_subscriptions').upsert({
        user_id: currentUser.id,
        subscription_data: subscription,
        created_at: new Date().toISOString()
      });
      
      if (error) console.error('Failed to save subscription:', error);
      */
    } catch (error) {
      console.error('Failed to send subscription to server:', error);
    }
  }
}

// ========================================
// INTEGRATION WITH EXISTING NOTIFICATION SYSTEM
// ========================================

// Global instance
let enhancedNotifications = null;

// Initialize enhanced notifications when page loads
document.addEventListener('DOMContentLoaded', async () => {
  enhancedNotifications = new EnhancedNotifications();
  const initialized = await enhancedNotifications.init();
  
  if (initialized) {
    console.log('🔔 Enhanced notifications ready!');
  }
});

// Enhanced setup function that combines everything
async function setupEnhancedNotifications(settings) {
  if (!enhancedNotifications) return;

  try {
    // Subscribe to push notifications if not already subscribed
    if (!enhancedNotifications.isSubscribed) {
      await enhancedNotifications.subscribe();
    }

    // Schedule notifications based on user preferences
    if (settings.dailyWorkoutReminder) {
      enhancedNotifications.scheduleWorkoutReminder(settings.workoutTime);
    }

    if (settings.motivationMessages) {
      enhancedNotifications.scheduleMotivationMessage();
    }

    if (settings.progressPhotoReminder) {
      enhancedNotifications.scheduleProgressReminder();
    }

    console.log('✅ Enhanced notifications configured');
  } catch (error) {
    console.error('Failed to setup enhanced notifications:', error);
  }
}

// Test function for enhanced notifications
async function testEnhancedNotification() {
  if (!enhancedNotifications) {
    alert('Enhanced notifications not initialized');
    return;
  }

  try {
    await enhancedNotifications.sendTestNotification();
    showToast('Enhanced notification sent! Check your browser/device 🔔', 'success');
  } catch (error) {
    console.error('Test notification failed:', error);
    showToast('Failed to send test notification', 'error');
  }
} 