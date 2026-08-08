// Firebase Cloud Messaging Service Worker
// Uses Firebase compat SDK 10.14.1 for background message handling.

importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

// Initialize Firebase with the web config.
// This MUST match the config in firebase_options.dart for the web platform.
firebase.initializeApp({
  apiKey: 'AIzaSyBMi8_tkec_On_EedikNuQ5c4fWo4p1ECQ',
  authDomain: 'lonceng-unman.firebaseapp.com',
  projectId: 'lonceng-unman',
  storageBucket: 'lonceng-unman.firebasestorage.app',
  messagingSenderId: '480883379106',
  appId: '1:480883379106:web:0ba3f4f02c1c2384c940fb',
  measurementId: 'G-ZCP2X7EEV8',
});

// Retrieve an instance of Firebase Messaging so it can handle background messages.
const messaging = firebase.messaging();

// Handle background messages when the app is not in focus.
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Background message received:', payload);

  const notificationTitle = payload.notification?.title ?? 'Lonceng UnMan';
  const notificationOptions = {
    body: payload.notification?.body ?? '',
    icon: '/icons/Icon-192.png',
    data: payload.data,
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click events.
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification clicked:', event.notification);

  event.notification.close();

  // Open the app when the notification is clicked.
  const urlToOpen = new URL('/', self.location.origin).href;

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      // If a window is already open, focus it.
      for (const client of windowClients) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          return client.focus();
        }
      }
      // Otherwise, open a new window.
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen);
      }
    }),
  );
});
