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
  const activity = event.data.json();
  console.log("received push", activity);

  const template =
    convertActivity(activity) || "A push notification has been sent";

  const options = {
    body: await translate(template),
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
    ],
  };

  event.waitUntil(
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    self.registration.showNotification("Push Notification", options)
  );
});

async function translate(template: string): Promise<string> {
  const DEFAULT_LOCALE = "en_US";

  let vueI18n = new VueI18n({
    locale: DEFAULT_LOCALE, // set locale
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    messages: en, // set locale messages
    fallbackLocale: DEFAULT_LOCALE,
    formatFallbackMessages: true,
    pluralizationRules,
  });

  vueI18n = await loadLanguageAsync(vueI18n, getLocale());
  return vueI18n.t(template) as string;
}

function getLocale(): string {
  const language = (
    (window.navigator as any).userLanguage || window.navigator.language
  ).replace(/-/, "_");

  return language && Object.prototype.hasOwnProperty.call(langs, language)
    ? language
    : language.split("-")[0];
}

export async function loadLanguageAsync(
  i18n: VueI18n,
  lang: string
): Promise<VueI18n> {
  // If the same language
  if (i18n.locale === lang) {
    return Promise.resolve(setI18nLanguage(i18n, lang));
  }

  // If the language hasn't been loaded yet
  const newMessages = await import(
    /* webpackChunkName: "lang-[request]" */ `@/i18n/${vueI18NfileForLanguage(
      lang
    )}.json`
  );
  i18n.setLocaleMessage(lang, newMessages.default);
  return setI18nLanguage(i18n, lang);
}

function setI18nLanguage(i18n: VueI18n, lang: string): VueI18n {
  i18n.locale = lang;
  return i18n;
}

function fileForLanguage(matches: Record<string, string>, lang: string) {
  if (Object.prototype.hasOwnProperty.call(matches, lang)) {
    return matches[lang];
  }
  return lang;
}

function vueI18NfileForLanguage(lang: string) {
  const matches: Record<string, string> = {
    fr: "fr_FR",
    en: "en_US",
  };
  return fileForLanguage(matches, lang);
}
