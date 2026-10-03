// Enhanced Service Worker for Gymcyclopedia
// Provides SMS-like notifications that work even when browser is closed

const CACHE_NAME = 'gymcyclopedia-enhanced-v1';

// Install event - cache essential files
self.addEventListener('install', (event) => {
  console.log('🔧 Enhanced Service Worker installing...');
  
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        return cache.addAll([
          '/',
          '/workouts.html',
          '/index.html',
          '/enhanced-notifications.js'
        ]);
      })
      .then(() => {
        console.log('✅ Enhanced Service Worker installed and cached files');
        return self.skipWaiting();
      })
  );
});

// Activate event
self.addEventListener('activate', (event) => {
  console.log('🚀 Enhanced Service Worker activating...');
  
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            console.log('🗑️ Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => {
      console.log('✅ Enhanced Service Worker activated');
      return self.clients.claim();
    })
  );
});

// Push event - handle incoming push notifications
self.addEventListener('push', (event) => {
  console.log('📨 Push notification received:', event);
  
  let options = {
    title: '💪 Gymcyclopedia',
    body: 'Time for your workout! Let\'s crush those goals! 🔥',
    icon: '/icon-192.png',
    badge: '/badge-72.png',
    tag: 'gymcyclopedia-reminder',
    requireInteraction: true,
    actions: [
      {
        action: 'open-app',
        title: '🚀 Open Gymcyclopedia'
      },
      {
        action: 'snooze',
        title: '⏰ Snooze 30min'
      }
    ],
    data: {
      url: '/workouts.html',
      timestamp: Date.now()
    }
  };

  // If the push event has data, use it
  if (event.data) {
    try {
      const payload = event.data.json();
      options = { ...options, ...payload };
    } catch (error) {
      console.warn('Could not parse push data:', error);
    }
  }

  event.waitUntil(
    self.registration.showNotification(options.title, options)
  );
});

// Notification click event
self.addEventListener('notificationclick', (event) => {
  console.log('🖱️ Notification clicked:', event);
  
  const notification = event.notification;
  const action = event.action;
  
  notification.close();

  if (action === 'snooze') {
    // Schedule a new notification in 30 minutes
    console.log('⏰ Snoozing notification for 30 minutes');
    
    setTimeout(() => {
      self.registration.showNotification('💪 Workout Reminder (Snoozed)', {
        body: 'Ready to workout now? Your muscles are waiting! 🔥',
        icon: '/icon-192.png',
        tag: 'gymcyclopedia-snooze',
        requireInteraction: true,
        actions: [
          {
            action: 'open-app',
            title: '🚀 Start Workout'
          }
        ]
      });
    }, 30 * 60 * 1000); // 30 minutes
    
    return;
  }

  // Default action or 'open-app' - open the app
  const urlToOpen = notification.data?.url || '/workouts.html';
  
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        // Check if the app is already open
        for (const client of clientList) {
          if (client.url.includes(urlToOpen) && 'focus' in client) {
            console.log('📱 Focusing existing app window');
            return client.focus();
          }
        }
        
        // If app is not open, open it
        if (clients.openWindow) {
          console.log('🚀 Opening new app window');
          return clients.openWindow(urlToOpen);
        }
      })
      .catch((error) => {
        console.error('Error handling notification click:', error);
      })
  );
});

// Background sync for offline functionality
self.addEventListener('sync', (event) => {
  console.log('🔄 Background sync triggered:', event.tag);
  
  if (event.tag === 'workout-reminder-sync') {
    event.waitUntil(
      // Send any pending reminders when back online
      sendPendingReminders()
    );
  }
});

// Fetch event - handle network requests
self.addEventListener('fetch', (event) => {
  // Only handle same-origin requests
  if (!event.request.url.startsWith(self.location.origin)) {
    return;
  }

  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        // Return cached version if available
        if (response) {
          return response;
        }

        // Otherwise fetch from network
        return fetch(event.request)
          .then((response) => {
            // Cache successful responses
            if (response.status === 200) {
              const responseClone = response.clone();
              caches.open(CACHE_NAME)
                .then((cache) => {
                  cache.put(event.request, responseClone);
                });
            }
            return response;
          });
      })
      .catch(() => {
        // Return offline page if available
        if (event.request.mode === 'navigate') {
          return caches.match('/offline.html');
        }
      })
  );
});

// Helper function to send pending reminders
async function sendPendingReminders() {
  try {
    // This could check localStorage or IndexedDB for pending reminders
    console.log('📤 Checking for pending workout reminders...');
    
    // Example: Show a reminder if it's workout time
    const now = new Date();
    const hour = now.getHours();
    
    // If it's 6 PM (18:00), show workout reminder
    if (hour === 18 && now.getMinutes() < 5) {
      self.registration.showNotification('🏋️ Workout Time!', {
        body: 'Time to crush your fitness goals! Open Gymcyclopedia now! 💪',
        icon: '/icon-192.png',
        tag: 'auto-workout-reminder',
        requireInteraction: true,
        actions: [
          {
            action: 'open-app',
            title: '🚀 Start Workout'
          }
        ]
      });
    }
    
  } catch (error) {
    console.error('Error sending pending reminders:', error);
  }
}

// Message handling from main thread
self.addEventListener('message', (event) => {
  console.log('📨 Service Worker received message:', event.data);
  
  if (event.data && event.data.type === 'SCHEDULE_REMINDER') {
    const { title, body, time } = event.data;
    
    // Calculate delay until reminder time
    const now = new Date();
    const [hours, minutes] = time.split(':');
    const reminderTime = new Date();
    reminderTime.setHours(parseInt(hours), parseInt(minutes), 0, 0);
    
    if (reminderTime <= now) {
      reminderTime.setDate(reminderTime.getDate() + 1);
    }
    
    const delay = reminderTime.getTime() - now.getTime();
    
    // Schedule the reminder
    setTimeout(() => {
      self.registration.showNotification(title, {
        body: body,
        icon: '/icon-192.png',
        tag: 'scheduled-reminder',
        requireInteraction: true,
        actions: [
          {
            action: 'open-app',
            title: '🚀 Open App'
          }
        ]
      });
    }, delay);
    
    console.log(`⏰ Reminder scheduled for ${reminderTime.toLocaleString()}`);
  }
}); 