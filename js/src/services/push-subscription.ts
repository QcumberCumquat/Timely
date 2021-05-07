import apolloProvider from "@/vue-apollo";
import ApolloClient from "apollo-client";
import { NormalizedCacheObject } from "apollo-cache-inmemory";
import { WEB_PUSH } from "../graphql/config";
import { IConfig } from "../types/config.model";

function urlBase64ToUint8Array(base64String: string): Uint8Array {
  const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/");

  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);

  for (let i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
}

export async function subscribeUserToPush(): Promise<PushSubscription | null> {
  const client = apolloProvider.defaultClient as ApolloClient<NormalizedCacheObject>;

  const registration = await navigator.serviceWorker.ready;
  const { data } = await client.mutate<{ config: IConfig }>({
    mutation: WEB_PUSH,
  });

  if (data?.config?.webPush?.enabled && data?.config?.webPush?.publicKey) {
    const subscribeOptions = {
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(
        data?.config?.webPush?.publicKey
      ),
    };
    const pushSubscription = await registration.pushManager.subscribe(
      subscribeOptions
    );
    console.log(
      "Received PushSubscription: ",
      JSON.stringify(pushSubscription)
    );
    return pushSubscription;
  }
  return null;
}

export async function isSubscribed(): Promise<boolean> {
  const registration = await navigator.serviceWorker.ready;
  return (await registration.pushManager.getSubscription()) !== null;
}
