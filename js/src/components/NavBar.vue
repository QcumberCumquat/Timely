<template>
  <b-navbar
    id="navbar"
    type="is-secondary"
    wrapper-class="container"
    :active.sync="mobileNavbarActive"
  >
    <template slot="brand">
      <b-navbar-item
        tag="router-link"
        :to="{ name: RouteName.HOME }"
        :aria-label="$t('Home')"
      >
        <logo />
      </b-navbar-item>
    </template>
    <template slot="start">
      <b-navbar-item tag="router-link" :to="{ name: RouteName.SEARCH }">{{
        $t("Explore")
      }}</b-navbar-item>
      <b-navbar-item
        v-if="currentActor.id && currentUser.isLoggedIn"
        tag="router-link"
        :to="{ name: RouteName.MY_EVENTS }"
        >{{ $t("My events") }}</b-navbar-item
      >
      <b-navbar-item
        tag="router-link"
        :to="{ name: RouteName.MY_GROUPS }"
        v-if="
          config &&
          config.features.groups &&
          currentActor.id &&
          currentUser.isLoggedIn
        "
        >{{ $t("My groups") }}</b-navbar-item
      >
      <b-navbar-item
        tag="span"
        v-if="
          config &&
          config.features.eventCreation &&
          currentActor.id &&
          currentUser.isLoggedIn
        "
      >
        <b-button
          v-if="!hideCreateEventsButton"
          tag="router-link"
          :to="{ name: RouteName.CREATE_EVENT }"
          type="is-primary"
          >{{ $t("Create") }}</b-button
        >
      </b-navbar-item>
      <b-navbar-item
        v-if="config && config.features.koenaConnect"
        class="koena"
        tag="a"
        href="https://mediation.koena.net/framasoft/mobilizon/"
        target="_blank"
        rel="noopener external"
        hreflang="fr"
      >
        <img
          src="/img/koena-a11y.svg"
          width="150"
          alt="Contact accessibilité"
        />
      </b-navbar-item>
    </template>
    <template slot="end">
      <b-navbar-item tag="div">
        <search-field @navbar-search="mobileNavbarActive = false" />
      </b-navbar-item>

      <b-navbar-dropdown
        v-if="currentActor.id && currentUser.isLoggedIn"
        right
        collapsible
        ref="user-dropdown"
        tabindex="0"
        tag="span"
        @keyup.enter="toggleMenu"
      >
        <template
          slot="label"
          v-if="currentActor"
          class="navbar-dropdown-profile"
        >
          <div class="identity-wrapper">
            <div>
              <figure class="image is-32x32" v-if="currentActor.avatar">
                <img
                  class="is-rounded"
                  alt="avatarUrl"
                  :src="currentActor.avatar.url"
                />
              </figure>
              <b-icon v-else icon="account-circle" />
            </div>
            <div class="media-content is-hidden-desktop">
              <span>{{ displayName(currentActor) }}</span>
              <span class="has-text-grey-dark" v-if="currentActor.name"
                >@{{ currentActor.preferredUsername }}</span
              >
            </div>
          </div>
        </template>

        <!-- No identities dropdown if no identities -->
        <span v-if="identities.length <= 1" />
        <b-navbar-item
          tag="span"
          v-for="identity in identities"
          v-else
          :active="identity.id === currentActor.id"
          :key="identity.id"
          tabindex="0"
          @click="setIdentity(identity)"
          @keyup.enter="setIdentity(identity)"
        >
          <span>
            <div class="media-left">
              <figure class="image is-32x32" v-if="identity.avatar">
                <img
                  class="is-rounded"
                  loading="lazy"
                  :src="identity.avatar.url"
                  alt
                />
              </figure>
              <b-icon v-else size="is-medium" icon="account-circle" />
            </div>

            <div class="media-content">
              <span>{{ displayName(identity) }}</span>
              <span class="has-text-grey-dark" v-if="identity.name"
                >@{{ identity.preferredUsername }}</span
              >
            </div>
          </span>

          <hr class="navbar-divider" role="presentation" />
        </b-navbar-item>

        <b-navbar-item
          tag="router-link"
          :to="{ name: RouteName.UPDATE_IDENTITY }"
          >{{ $t("My account") }}</b-navbar-item
        >
        <b-navbar-item
          v-if="currentUser.role === ICurrentUserRole.ADMINISTRATOR"
          tag="router-link"
          :to="{ name: RouteName.ADMIN_DASHBOARD }"
          >{{ $t("Administration") }}</b-navbar-item
        >

        <b-navbar-item
          tag="span"
          tabindex="0"
          @click="logout"
          @keyup.enter="logout"
        >
          <span>{{ $t("Log out") }}</span>
        </b-navbar-item>
      </b-navbar-dropdown>

      <b-navbar-item v-else tag="div">
        <div class="buttons">
          <router-link
            class="button is-primary"
            v-if="config && config.registrationsOpen"
            :to="{ name: RouteName.REGISTER }"
          >
            <strong>{{ $t("Sign up") }}</strong>
          </router-link>

          <router-link
            class="button is-light"
            :to="{ name: RouteName.LOGIN }"
            >{{ $t("Log in") }}</router-link
          >
        </div>
      </b-navbar-item>
    </template>
  </b-navbar>
</template>

<script lang="ts">
import { Component, Ref, Vue, Watch } from "vue-property-decorator";
import Logo from "@/components/Logo.vue";
import { GraphQLError } from "graphql";
import { loadLanguageAsync } from "@/utils/i18n";
import { ICurrentUserRole } from "@/types/enums";
import { CURRENT_USER_CLIENT, USER_SETTINGS } from "../graphql/user";
import { changeIdentity, logout } from "../utils/auth";
import {
  CURRENT_ACTOR_CLIENT,
  IDENTITIES,
  UPDATE_DEFAULT_ACTOR,
} from "../graphql/actor";
import { displayName, IPerson, Person } from "../types/actor";
import { CONFIG } from "../graphql/config";
import { IConfig } from "../types/config.model";
import { ICurrentUser, IUser } from "../types/current-user.model";
import SearchField from "./SearchField.vue";
import RouteName from "../router/name";

@Component({
  apollo: {
    currentUser: CURRENT_USER_CLIENT,
    currentActor: CURRENT_ACTOR_CLIENT,
    identities: {
      query: IDENTITIES,
      update: ({ identities }) =>
        identities
          ? identities.map((identity: IPerson) => new Person(identity))
          : [],
      skip() {
        return this.currentUser.isLoggedIn === false;
      },
      error({ graphQLErrors }) {
        this.handleErrors(graphQLErrors);
      },
    },
    config: CONFIG,
    loggedUser: {
      query: USER_SETTINGS,
      skip() {
        return !this.currentUser || this.currentUser.isLoggedIn === false;
      },
    },
  },
  components: {
    Logo,
    SearchField,
  },
})
export default class NavBar extends Vue {
  currentActor!: IPerson;

  config!: IConfig;

  currentUser!: ICurrentUser;

  loggedUser!: IUser;

  ICurrentUserRole = ICurrentUserRole;

  identities: IPerson[] = [];

  RouteName = RouteName;

  mobileNavbarActive = false;

  displayName = displayName;

  @Ref("user-dropdown") userDropDown!: any;

  toggleMenu(): void {
    console.debug("called toggleMenu");
    this.userDropDown.showMenu();
  }

  @Watch("currentActor")
  async initializeListOfIdentities(): Promise<void> {
    if (!this.currentUser.isLoggedIn) return;
    const { data } = await this.$apollo.query<{ identities: IPerson[] }>({
      query: IDENTITIES,
    });
    if (data) {
      this.identities = data.identities.map(
        (identity: IPerson) => new Person(identity)
      );

      // If we don't have any identities, the user has validated their account,
      // is logging for the first time but didn't create an identity somehow
      if (this.identities.length === 0) {
        try {
          await this.$router.push({
            name: RouteName.REGISTER_PROFILE,
            params: {
              email: this.currentUser.email,
              userAlreadyActivated: "true",
            },
          });
        } catch (err) {
          return undefined;
        }
      }
    }
  }

  @Watch("loggedUser")
  setSavedLanguage(): void {
    if (this.loggedUser?.locale) {
      console.debug("Setting locale from navbar");
      loadLanguageAsync(this.loggedUser.locale);
    }
  }

  async handleErrors(errors: GraphQLError[]): Promise<void> {
    if (
      errors.length > 0 &&
      errors[0].message ===
        "You need to be logged-in to view your list of identities"
    ) {
      await this.logout();
    }
  }

  async logout(): Promise<void> {
    await logout(this.$apollo.provider.defaultClient);
    this.$buefy.notification.open({
      message: this.$t("You have been disconnected") as string,
      type: "is-success",
      position: "is-bottom-right",
      duration: 5000,
    });

    if (this.$route.name === RouteName.HOME) return;
    await this.$router.push({ name: RouteName.HOME });
  }

  async setIdentity(identity: IPerson): Promise<void> {
    await this.$apollo.mutate({
      mutation: UPDATE_DEFAULT_ACTOR,
      variables: {
        preferredUsername: identity.preferredUsername,
      },
    });
    return changeIdentity(this.$apollo.provider.defaultClient, identity);
  }

  get hideCreateEventsButton(): boolean {
    return !!this.config?.restrictions?.onlyGroupsCanCreateEvents;
  }
}
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
nav {
  .navbar-item {
    a.button {
      font-weight: bold;
    }

    svg {
      height: 1.75rem;
    }
  }

  .navbar-dropdown .navbar-item {
    cursor: pointer;

    span {
      display: flex;
    }

    &.is-active {
      background: $secondary;
    }

    span.icon.is-medium {
      display: flex;
    }

    img {
      max-height: 2.5em;
    }
  }

  .navbar-item.has-dropdown a.navbar-link figure {
    @include margin-right(0.75rem);
    display: flex;
    align-items: center;
  }

  a.navbar-item:focus-within {
    background-color: inherit;
  }

  .koena {
    padding-top: 0;
    padding-bottom: 0;
    & > img {
      max-height: 4rem;
      padding-top: 0.2rem;
    }
  }

  .identity-wrapper {
    display: flex;

    .media-content span {
      display: flex;
      color: $violet-2;
    }
  }
}
</style>
