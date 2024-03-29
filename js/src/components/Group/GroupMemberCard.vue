<template>
  <div class="card">
    <div class="identity-header" dir="auto">
      <figure class="image is-24x24" v-if="member.actor.avatar">
        <img class="is-rounded" :src="member.actor.avatar.url" alt="" />
      </figure>
      <b-icon v-else icon="account-circle" />
      {{ displayNameAndUsername(member.actor) }}
    </div>
    <div class="card-content" dir="auto">
      <div>
        <div class="media">
          <div class="media-left">
            <figure class="image is-48x48" v-if="member.parent.avatar">
              <img class="is-rounded" :src="member.parent.avatar.url" alt="" />
            </figure>
            <b-icon v-else size="is-large" icon="account-group" />
          </div>
          <div class="media-content" dir="auto">
            <router-link
              :to="{
                name: RouteName.GROUP,
                params: {
                  preferredUsername: usernameWithDomain(member.parent),
                },
              }"
            >
              <h2>{{ member.parent.name }}</h2>
              <p class="is-6 has-text-grey-dark">
                <span>{{ `@${usernameWithDomain(member.parent)}` }}</span>
                <b-taglist>
                  <b-tag
                    type="is-info"
                    v-if="member.role === MemberRole.ADMINISTRATOR"
                    >{{ $t("Administrator") }}</b-tag
                  >
                  <b-tag
                    type="is-info"
                    v-else-if="member.role === MemberRole.MODERATOR"
                    >{{ $t("Moderator") }}</b-tag
                  >
                </b-taglist>
              </p>
            </router-link>
          </div>
        </div>
        <div class="content" v-if="member.parent.summary">
          <p v-html="member.parent.summary" />
        </div>
      </div>
      <div>
        <b-dropdown aria-role="list" position="is-bottom-left">
          <b-icon icon="dots-horizontal" slot="trigger" />

          <b-dropdown-item aria-role="listitem" @click="$emit('leave')">
            <b-icon icon="exit-to-app" />
            {{ $t("Leave") }}
          </b-dropdown-item>
        </b-dropdown>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { displayNameAndUsername, usernameWithDomain } from "@/types/actor";
import { IMember } from "@/types/actor/member.model";
import { MemberRole } from "@/types/enums";
import RouteName from "../../router/name";

@Component
export default class GroupMemberCard extends Vue {
  @Prop({ required: true }) member!: IMember;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;

  displayNameAndUsername = displayNameAndUsername;

  MemberRole = MemberRole;
}
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
.card {
  .card-content {
    display: flex;
    align-items: center;

    & > div:first-child {
      flex: 1;
    }

    & > div:last-child {
      cursor: pointer;
    }

    .media-content {
      ::v-deep .tags {
        margin-bottom: 0;
      }
    }
  }

  .identity-header {
    background: $yellow-2;
    display: flex;
    padding: 5px;

    figure,
    span.icon {
      @include padding-right(3px);
    }
  }
}
</style>
