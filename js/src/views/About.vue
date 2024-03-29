<template>
  <div>
    <section class="container">
      <div class="columns">
        <div class="column is-one-quarter-desktop">
          <aside class="menu">
            <p class="menu-list">
              <router-link :to="{ name: RouteName.ABOUT_INSTANCE }">{{
                $t("About this instance")
              }}</router-link>
            </p>
            <p class="menu-label has-text-grey-dark">
              {{ $t("Legal") }}
            </p>
            <ul class="menu-list">
              <li>
                <router-link :to="{ name: RouteName.TERMS }">{{
                  $t("Terms of service")
                }}</router-link>
              </li>
              <li>
                <router-link :to="{ name: RouteName.PRIVACY }">{{
                  $t("Privacy policy")
                }}</router-link>
              </li>
              <li>
                <router-link :to="{ name: RouteName.RULES }">{{
                  $t("Instance rules")
                }}</router-link>
              </li>
              <li>
                <router-link :to="{ name: RouteName.GLOSSARY }">{{
                  $t("Glossary")
                }}</router-link>
              </li>
            </ul>
          </aside>
        </div>
        <div class="column router">
          <router-view />
        </div>
      </div>
    </section>
    <div class="hero intro is-small is-secondary">
      <div class="hero-body">
        <div class="container">
          <h1 class="title">{{ $t("Powered by Mobilizon") }}</h1>
          <p>
            {{
              $t(
                "A user-friendly, emancipatory and ethical tool for gathering, organising, and mobilising."
              )
            }}
          </p>
          <b-button
            icon-left="open-in-new"
            size="is-large"
            type="is-primary"
            tag="a"
            href="https://joinmobilizon.org"
            >{{ $t("Learn more") }}</b-button
          >
        </div>
      </div>
    </div>
    <div
      class="hero register is-primary is-medium"
      v-if="!currentUser || !currentUser.id"
    >
      <div class="hero-body">
        <div class="container has-text-centered">
          <div class="columns">
            <div class="column" v-if="config && config.registrationsOpen">
              <h2 class="title">{{ $t("Register on this instance") }}</h2>
              <b-button
                type="is-secondary"
                size="is-large"
                tag="router-link"
                :to="{ name: RouteName.REGISTER }"
                >{{ $t("Create an account") }}</b-button
              >
            </div>
            <div class="column">
              <h2 class="title">{{ $t("Find another instance") }}</h2>
              <b-button
                type="is-secondary"
                size="is-large"
                tag="a"
                href="https://mobilizon.org"
                >{{ $t("Pick an instance") }}</b-button
              >
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { CONFIG } from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import RouteName from "../router/name";
import { CURRENT_USER_CLIENT } from "@/graphql/user";
import { ICurrentUser } from "@/types/current-user.model";

@Component({
  apollo: {
    config: CONFIG,
    currentUser: CURRENT_USER_CLIENT,
  },
  metaInfo() {
    return {
      title: this.$t("About {instance}", {
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        instance: this?.config?.name,
      }) as string,
    };
  },
})
export default class About extends Vue {
  config!: IConfig;
  currentUser!: ICurrentUser;

  RouteName = RouteName;
}
</script>

<style lang="scss" scoped>
.hero.is-primary {
  background: $background-color;

  .title {
    margin: 30px auto 1rem auto;
  }

  p {
    margin-bottom: 1rem;
  }
}

.hero.register {
  .title {
    color: $violet-1;
  }
  background: $purple-2;
}

aside.menu {
  position: sticky;
  top: 2rem;
  margin-top: 2rem;
}

.router.column {
  background: $white;
}

ul.menu-list > li > a {
  text-decoration: none;
}
</style>
