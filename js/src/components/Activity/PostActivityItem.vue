<template>
  <div class="activity-item">
    <b-icon :icon="'bullhorn'" :type="iconColor" />
    <div class="subject">
      <i18n :path="translation" tag="p">
        <router-link
          v-if="activity.object"
          slot="post"
          :to="{
            name: RouteName.POST,
            params: { slug: subjectParams.post_slug },
          }"
          >{{ subjectParams.post_title }}</router-link
        >
        <b v-else slot="post">{{ subjectParams.post_title }}</b>
        <popover-actor-card
          :actor="activity.author"
          :inline="true"
          slot="profile"
        >
          <b>
            {{
              $t("@{username}", {
                username: usernameWithDomain(activity.author),
              })
            }}</b
          ></popover-actor-card
        ></i18n
      >
      <small class="has-text-grey activity-date">{{
        activity.insertedAt | formatTimeString
      }}</small>
    </div>
  </div>
</template>
<script lang="ts">
import { usernameWithDomain } from "@/types/actor";
import { ActivityPostSubject } from "@/types/enums";
import { Component } from "vue-property-decorator";
import RouteName from "../../router/name";
import PopoverActorCard from "../Account/PopoverActorCard.vue";
import ActivityMixin from "../../mixins/activity";
import { mixins } from "vue-class-component";
import { convertActivity } from "@/services/activity-converter";

@Component({
  components: {
    PopoverActorCard,
  },
})
export default class PostActivityItem extends mixins(ActivityMixin) {
  usernameWithDomain = usernameWithDomain;
  RouteName = RouteName;
  ActivityPostSubject = ActivityPostSubject;

  get translation(): string | undefined {
    return convertActivity(this.activity, {
      isAuthorCurrentActor: this.isAuthorCurrentActor,
    });
  }

  get iconColor(): string | undefined {
    switch (this.activity.subject) {
      case ActivityPostSubject.POST_CREATED:
        return "is-success";
      case ActivityPostSubject.POST_UPDATED:
        return "is-grey";
      case ActivityPostSubject.POST_DELETED:
        return "is-danger";
      default:
        return undefined;
    }
  }
}
</script>
<style lang="scss" scoped>
@import "./activity.scss";
</style>
