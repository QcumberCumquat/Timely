<template>
  <div id="mobilizon">
    <NavBar />
    <div class="container" v-if="config && config.demoMode">
      <b-message type="is-info" :title="$t('Demo mode')" closable aria-close-label="Close">
        <p
          v-html="
            `${$t('This is a demonstration website to test Mobilizon.')} ${$t(
              '<b>Please do not use it in any real way.</b>'
            )} ${$t('Data is deleted every 7 days.')}`
          "
        />
      </b-message>
    </div>
    <main>
      <transition name="fade" mode="out-in">
        <router-view />
      </transition>
    </main>
    <mobilizon-footer />
  </div>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import NavBar from "./components/NavBar.vue";
import { AUTH_ACCESS_TOKEN, AUTH_USER_EMAIL, AUTH_USER_ID, AUTH_USER_ROLE } from "./constants";
import { CURRENT_USER_CLIENT, UPDATE_CURRENT_USER_CLIENT } from "./graphql/user";
import Footer from "./components/Footer.vue";
import Logo from "./components/Logo.vue";
import { initializeCurrentActor } from "./utils/auth";
import { CONFIG } from "./graphql/config";
import { IConfig } from "./types/config.model";
import { ICurrentUser } from "./types/current-user.model";

@Component({
  apollo: {
    currentUser: CURRENT_USER_CLIENT,
    config: CONFIG,
  },
  components: {
    Logo,
    NavBar,
    "mobilizon-footer": Footer,
  },
})
export default class App extends Vue {
  config!: IConfig;

  currentUser!: ICurrentUser;

  async created(): Promise<void> {
    if (await this.initializeCurrentUser()) {
      await initializeCurrentActor(this.$apollo.provider.defaultClient);
    }
  }

  private async initializeCurrentUser() {
    const userId = localStorage.getItem(AUTH_USER_ID);
    const userEmail = localStorage.getItem(AUTH_USER_EMAIL);
    const accessToken = localStorage.getItem(AUTH_ACCESS_TOKEN);
    const role = localStorage.getItem(AUTH_USER_ROLE);

    if (userId && userEmail && accessToken && role) {
      return this.$apollo.mutate({
        mutation: UPDATE_CURRENT_USER_CLIENT,
        variables: {
          id: userId,
          email: userEmail,
          isLoggedIn: true,
          role,
        },
      });
    }
    return false;
  }
}
</script>

<style lang="scss">
@import "variables";

/* Icons */
$mdi-font-path: "~@mdi/font/fonts";
@import "~@mdi/font/scss/materialdesignicons";

@import "common";
</style>
