// Service Worker for Gymcyclopedia Push Notifications
// Version 1.0

const CACHE_NAME = 'gymcyclopedia-v1';
const urlsToCache = [
  '/',
  '/workouts.html',
  '/ai-coaching.html',
  '/nutrition-recovery.html',
  '/blog.html',
  '/support.html',
  '/index.html'
];

// Install event
self.addEventListener('install', event => {
  console.log('Service Worker: Installing...');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('Service Worker: Caching files');
        return cache.addAll(urlsToCache);
      })
      .then(() => self.skipWaiting())
  );
});

// Activate event
self.addEventListener('activate', event => {
  console.log('Service Worker: Activating...');
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== CACHE_NAME) {
            console.log('Service Worker: Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch event
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        // Return cached version or fetch from network
        return response || fetch(event.request);
      })
  );
});

// Push event - handle incoming push notifications
self.addEventListener('push', event => {
  console.log('Service Worker: Push received');
  
  let data = {};
  if (event.data) {
    data = event.data.json();
  }
  
  const options = {
    body: data.body || 'Time for your workout!',
    icon: data.icon || '/favicon.ico',
    badge: '/favicon.ico',
    vibrate: [100, 50, 100],
    data: {
      dateOfArrival: Date.now(),
      primaryKey: data.primaryKey || 'default'
    },
    actions: [
      {
        action: 'explore',
        title: 'Start Workout',
        icon: '/favicon.ico'
      },
      {
        action: 'close',
        title: 'Close',
        icon: '/favicon.ico'
      }
    ]
  };
  
  event.waitUntil(
    self.registration.showNotification(data.title || 'Gymcyclopedia', options)
  );
});

// Notification click event
self.addEventListener('notificationclick', event => {
  console.log('Service Worker: Notification clicked');
  
  event.notification.close();
  
  if (event.action === 'explore') {
    // Open the workout page
    event.waitUntil(
      clients.openWindow('/workouts.html')
    );
  } else if (event.action === 'close') {
    // Just close the notification
    event.notification.close();
  } else {
    // Default action - open the app
    event.waitUntil(
      clients.openWindow('/')
    );
  }
});

// Background sync event
self.addEventListener('sync', event => {
  console.log('Service Worker: Background sync');
  
  if (event.tag === 'background-sync') {
    event.waitUntil(doBackgroundSync());
  }
});

// Background sync function
async function doBackgroundSync() {
  try {
    // Sync any pending data
    console.log('Service Worker: Performing background sync');
    // Add your sync logic here
  } catch (error) {
    console.error('Service Worker: Background sync failed:', error);
  }
}

// Message event - handle messages from main thread
self.addEventListener('message', event => {
  console.log('Service Worker: Message received:', event.data);
  
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  
  if (event.data && event.data.type === 'SCHEDULE_NOTIFICATION') {
    const { title, body, delay, icon } = event.data;
    
    setTimeout(() => {
      self.registration.showNotification(title, {
        body: body,
        icon: icon || '/favicon.ico',
        badge: '/favicon.ico',
        vibrate: [100, 50, 100],
        requireInteraction: false,
        actions: [
          {
            action: 'start',
            title: 'Start Workout'
          },
          {
            action: 'snooze',
            title: 'Remind Later'
          }
        ]
      });
    }, delay);
  }
});

// Handle notification action clicks
self.addEventListener('notificationclick', event => {
  const clickedNotification = event.notification;
  clickedNotification.close();
  
  // Handle different actions
  if (event.action === 'start') {
    // Open workout page
    event.waitUntil(
      clients.openWindow('/workouts.html')
    );
  } else if (event.action === 'snooze') {
    // Schedule another notification in 30 minutes
    setTimeout(() => {
      self.registration.showNotification('Workout Reminder', {
        body: 'Ready for your workout now?',
        icon: '/favicon.ico',
        badge: '/favicon.ico'
      });
    }, 30 * 60 * 1000); // 30 minutes
  } else {
    // Default click - open the app
    event.waitUntil(
      clients.openWindow('/')
    );
  }
});

// Error event
self.addEventListener('error', event => {
  console.error('Service Worker: Error occurred:', event.error);
});

// Unhandled rejection event
self.addEventListener('unhandledrejection', event => {
  console.error('Service Worker: Unhandled rejection:', event.reason);
}); 