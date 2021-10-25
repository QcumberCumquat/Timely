if (import.meta.env.MODE !== "development") {
  // @ts-ignore
  import("vite/modulepreload-polyfill");
}
import Vue from "vue";
import Buefy from "buefy";
import Component from "vue-class-component";
import VueScrollTo from "vue-scrollto";
import VueMeta from "vue-meta";
import VTooltip from "v-tooltip";
import VueAnnouncer from "@vue-a11y/announcer";
import VueSkipTo from "@vue-a11y/skip-to";
import App from "./App.vue";
import router from "./router";
import { NotifierPlugin } from "./plugins/notifier";
import filters from "./filters";
import { i18n } from "./utils/i18n";
import apolloProvider from "./vue-apollo";
import "./registerServiceWorker";
import SvgIcon from "./components/Utils/SVGIcon.vue";
// @ts-ignore
import mdiVue from "mdi-vue/v2";
import icons from "./icons";

Vue.config.productionTip = false;

Vue.use(Buefy, { defaultIconPack: null, defaultIconComponent: SvgIcon });
Vue.use(NotifierPlugin);
Vue.use(filters);
Vue.use(VueMeta);
Vue.use(VueScrollTo);
Vue.use(VTooltip);
Vue.use(VueAnnouncer);
Vue.use(VueSkipTo);
Vue.use(mdiVue, {
  icons,
});

// Register the router hooks with their names
Component.registerHooks([
  "beforeRouteEnter",
  "beforeRouteLeave",
  "beforeRouteUpdate", // for vue-router 2.2+
]);

/* eslint-disable no-new */
new Vue({
  router,
  apolloProvider,
  el: "#app",
  template: "<App/>",
  components: { App },
  render: (h) => h(App),
  i18n,
});
