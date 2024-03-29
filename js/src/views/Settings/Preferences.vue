<template>
  <div>
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link :to="{ name: RouteName.ACCOUNT_SETTINGS }">{{
            $t("Account")
          }}</router-link>
        </li>
        <li class="is-active">
          <router-link :to="{ name: RouteName.PREFERENCES }">{{
            $t("Preferences")
          }}</router-link>
        </li>
      </ul>
    </nav>
    <div>
      <b-field :label="$t('Language')" label-for="setting-language">
        <b-select
          :loading="!config || !loggedUser"
          v-model="locale"
          :placeholder="$t('Select a language')"
          id="setting-language"
        >
          <option v-for="(language, lang) in langs" :value="lang" :key="lang">
            {{ language }}
          </option>
        </b-select>
      </b-field>
      <b-field
        :label="$t('Timezone')"
        v-if="selectedTimezone"
        label-for="setting-timezone"
      >
        <b-select
          :placeholder="$t('Select a timezone')"
          :loading="!config || !loggedUser"
          v-model="selectedTimezone"
          id="setting-timezone"
        >
          <optgroup
            :label="group"
            v-for="(groupTimezones, group) in timezones"
            :key="group"
          >
            <option
              v-for="timezone in groupTimezones"
              :value="`${group}/${timezone}`"
              :key="timezone"
            >
              {{ sanitize(timezone) }}
            </option>
          </optgroup>
        </b-select>
      </b-field>
      <em v-if="Intl.DateTimeFormat().resolvedOptions().timeZone">{{
        $t("Timezone detected as {timezone}.", {
          timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        })
      }}</em>
      <b-message v-else type="is-danger">{{
        $t("Unable to detect timezone.")
      }}</b-message>
      <hr role="presentation" />
      <b-field grouped>
        <b-field
          :label="$t('City or region')"
          expanded
          label-for="setting-city"
        >
          <address-auto-complete
            v-if="loggedUser && loggedUser.settings"
            :type="AddressSearchType.ADMINISTRATIVE"
            :doGeoLocation="false"
            v-model="address"
            id="setting-city"
          >
          </address-auto-complete>
        </b-field>
        <b-field :label="$t('Radius')" label-for="setting-radius">
          <b-select
            :placeholder="$t('Select a radius')"
            v-model="locationRange"
            id="setting-radius"
          >
            <option
              v-for="index in [1, 5, 10, 25, 50, 100]"
              :key="index"
              :value="index"
            >
              {{ $tc("{count} km", index, { count: index }) }}
            </option>
          </b-select>
        </b-field>
        <b-button
          :disabled="address == undefined"
          @click="resetArea"
          @keyup.enter="resetArea"
          class="reset-area"
          icon-left="close"
          :aria-label="$t('Reset')"
        />
      </b-field>
      <p>
        {{
          $t(
            "Your city or region and the radius will only be used to suggest you events nearby. The event radius will consider the administrative center of the area."
          )
        }}
      </p>
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import ngeohash from "ngeohash";
import { saveLocaleData } from "@/utils/auth";
import { TIMEZONES } from "../../graphql/config";
import {
  USER_SETTINGS,
  SET_USER_SETTINGS,
  UPDATE_USER_LOCALE,
} from "../../graphql/user";
import { IConfig } from "../../types/config.model";
import { IUser, IUserSettings } from "../../types/current-user.model";
import langs from "../../i18n/langs.json";
import RouteName from "../../router/name";
import AddressAutoComplete from "../../components/Event/AddressAutoComplete.vue";
import { AddressSearchType } from "@/types/enums";
import { Address, IAddress } from "@/types/address.model";

@Component({
  apollo: {
    config: TIMEZONES,
    loggedUser: USER_SETTINGS,
  },
  components: {
    AddressAutoComplete,
  },
  metaInfo() {
    return {
      title: this.$t("Preferences") as string,
    };
  },
})
export default class Preferences extends Vue {
  config!: IConfig;

  loggedUser!: IUser;

  RouteName = RouteName;

  langs: Record<string, string> = langs;

  AddressSearchType = AddressSearchType;

  get selectedTimezone(): string {
    if (this.loggedUser?.settings?.timezone) {
      return this.loggedUser.settings.timezone;
    }
    const detectedTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    if (this.loggedUser?.settings?.timezone === null) {
      this.updateUserSettings({ timezone: detectedTimezone });
    }
    return detectedTimezone;
  }

  set selectedTimezone(selectedTimezone: string) {
    if (selectedTimezone !== this.loggedUser?.settings?.timezone) {
      this.updateUserSettings({ timezone: selectedTimezone });
    }
  }

  get locale(): string {
    if (this.loggedUser?.locale) {
      return this.loggedUser?.locale;
    }
    return this.$i18n.locale;
  }

  set locale(locale: string) {
    if (locale) {
      this.$apollo.mutate({
        mutation: UPDATE_USER_LOCALE,
        variables: {
          locale,
        },
      });
      saveLocaleData(locale);
    }
  }

  // eslint-disable-next-line class-methods-use-this
  sanitize(timezone: string): string {
    return timezone
      .split("_")
      .join(" ")
      .replace("St ", "St. ")
      .split("/")
      .join(" - ");
  }

  get timezones(): Record<string, string[]> {
    if (!this.config || !this.config.timezones) return {};
    return this.config.timezones.reduce(
      (acc: { [key: string]: Array<string> }, val: string) => {
        const components = val.split("/");
        const [prefix, suffix] = [
          components.shift() as string,
          components.join("/"),
        ];
        const pushOrCreate = (
          acc2: { [key: string]: Array<string> },
          prefix2: string,
          suffix2: string
        ) => {
          // eslint-disable-next-line no-param-reassign
          (acc2[prefix2] = acc2[prefix2] || []).push(suffix2);
          return acc2;
        };
        if (suffix) {
          return pushOrCreate(acc, prefix, suffix);
        }
        return pushOrCreate(acc, this.$t("Other") as string, prefix);
      },
      {}
    );
  }

  get address(): IAddress | null {
    if (
      this.loggedUser?.settings?.location?.name &&
      this.loggedUser?.settings?.location?.geohash
    ) {
      const { latitude, longitude } = ngeohash.decode(
        this.loggedUser?.settings?.location?.geohash
      );
      const name = this.loggedUser?.settings?.location?.name;
      return {
        description: name,
        locality: "",
        type: "administrative",
        geom: `${longitude};${latitude}`,
        street: "",
        postalCode: "",
        region: "",
        country: "",
      };
    }
    return null;
  }

  set address(address: IAddress | null) {
    if (address && address.geom) {
      const { geom } = address;
      const addressObject = new Address(address);
      const queryText = addressObject.poiInfos.name;
      const [lon, lat] = geom.split(";");
      const geohash = ngeohash.encode(lat, lon, 6);
      if (queryText && geom) {
        this.updateUserSettings({
          location: {
            geohash,
            name: queryText,
          },
        });
      }
    }
  }

  get locationRange(): number | undefined | null {
    return this.loggedUser?.settings?.location?.range;
  }

  set locationRange(locationRange: number | undefined | null) {
    if (locationRange) {
      this.updateUserSettings({
        location: {
          range: locationRange,
        },
      });
    }
  }

  resetArea(): void {
    this.updateUserSettings({
      location: {
        geohash: null,
        name: null,
        range: null,
      },
    });
  }

  private async updateUserSettings(userSettings: IUserSettings) {
    await this.$apollo.mutate<{ setUserSetting: string }>({
      mutation: SET_USER_SETTINGS,
      variables: userSettings,
      refetchQueries: [{ query: USER_SETTINGS }],
    });
  }
}
</script>
<style lang="scss" scoped>
.reset-area {
  align-self: center;
  position: relative;
  top: 10px;
}
</style>
