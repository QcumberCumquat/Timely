import { registerRoute } from "workbox-routing";
import {
  NetworkFirst,
  StaleWhileRevalidate,
  CacheFirst,
} from "workbox-strategies";

// Used for filtering matches based on status code, header, or both
import { CacheableResponsePlugin } from "workbox-cacheable-response";
// Used to limit entries in cache, remove entries after a certain period of time
import { ExpirationPlugin } from "workbox-expiration";

import { precacheAndRoute } from "workbox-precaching";

// Use with precache injection
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
// eslint-disable-next-line no-underscore-dangle
precacheAndRoute(self.__WB_MANIFEST);

registerRoute(
  // Check to see if the request is a navigation to a new page
  ({ request }) => request.mode === "navigate",
  // Use a Network First caching strategy
  new NetworkFirst({
    // Put all cached files in a cache named 'pages'
    cacheName: "pages",
    plugins: [
      // Ensure that only requests that result in a 200 status are cached
      new CacheableResponsePlugin({
        statuses: [200],
      }),
    ],
  })
);

// Cache CSS, JS, and Web Worker requests with a Stale While Revalidate strategy
registerRoute(
  // Check to see if the request's destination is style for stylesheets, script for JavaScript, or worker for web worker
  ({ request }) =>
    request.destination === "style" ||
    request.destination === "script" ||
    request.destination === "worker",
  // Use a Stale While Revalidate caching strategy
  new StaleWhileRevalidate({
    // Put all cached files in a cache named 'assets'
    cacheName: "assets",
    plugins: [
      // Ensure that only requests that result in a 200 status are cached
      new CacheableResponsePlugin({
        statuses: [200],
      }),
    ],
  })
);

// Cache images with a Cache First strategy
registerRoute(
  // Check to see if the request's destination is style for an image
  ({ request }) => request.destination === "image",
  // Use a Cache First caching strategy
  new CacheFirst({
    // Put all cached files in a cache named 'images'
    cacheName: "images",
    plugins: [
      // Ensure that only requests that result in a 200 status are cached
      new CacheableResponsePlugin({
        statuses: [200],
      }),
      // Don't cache more than 50 items, and expire them after 30 days
      new ExpirationPlugin({
        maxEntries: 50,
        maxAgeSeconds: 60 * 60 * 24 * 30, // 30 Days
      }),
    ],
  })
);

self.addEventListener("push", async (event: any) => {
  console.log("received push", event);
  const options = {
    body: "Ceci est une notification envoyée par Mobilizon !",
    icon: "images/notification-flat.png",
    vibrate: [100, 50, 100],
    data: {
      dateOfArrival: Date.now(),
      primaryKey: 1,
    },
    actions: [
      {
        action: "explore",
        title: "Go to the site",
        icon: "images/checkmark.png",
      },
      {
        action: "close",
        title: "Close the notification",
        icon: "images/xmark.png",
      },
    ],
  };

  event.waitUntil(
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    self.registration.showNotification("Push Notification", options)
  );
});
