/* eslint-disable no-console */

import { register } from "register-service-worker";

if ("serviceWorker" in navigator && isProduction()) {
  register(`${import.meta.env.BASE_URL}sw.js`, {
    ready() {
      console.debug(
        "App is being served from cache by a service worker.\n" +
          "For more details, visit https://goo.gl/AFskqB"
      );
    },
    registered() {
      console.debug("Service worker has been registered.");
    },
    cached() {
      console.debug("Content has been cached for offline use.");
    },
    updatefound() {
      console.debug("New content is downloading.");
    },
    updated(registration: ServiceWorkerRegistration) {
      const event = new CustomEvent("refreshApp", { detail: registration });
      document.dispatchEvent(event);
      console.debug("New content is available; please refresh.");
    },
    offline() {
      console.debug(
        "No internet connection found. App is running in offline mode."
      );
    },
    error(error) {
      console.error("Error during service worker registration:", error);
    },
  });
}

function isProduction(): boolean {
  return import.meta.env.MODE === "production";
}
