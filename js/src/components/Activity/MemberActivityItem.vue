<template>
  <div class="activity-item">
    <b-icon :icon="icon" :type="iconColor" />
    <div class="subject">
      <i18n :path="translation" tag="p">
        <popover-actor-card
          v-if="activity.object"
          :actor="activity.object.actor"
          :inline="true"
          slot="member"
        >
          <b>
            {{
              $t("@{username}", {
                username: usernameWithDomain(activity.object.actor),
              })
            }}</b
          ></popover-actor-card
        >
        <b slot="member" v-else>{{
          subjectParams.member_actor_federated_username
        }}</b>
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
import { ActivityMemberSubject } from "@/types/enums";
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
export default class MemberActivityItem extends mixins(ActivityMixin) {
  usernameWithDomain = usernameWithDomain;
  RouteName = RouteName;
  ActivityMemberSubject = ActivityMemberSubject;

  get translation(): string | undefined {
    return convertActivity(this.activity, {
      isAuthorCurrentActor: this.isAuthorCurrentActor,
      isObjectMemberCurrentActor: this.isObjectMemberCurrentActor,
    });
  }

  get icon(): string {
    switch (this.activity.subject) {
      case ActivityMemberSubject.MEMBER_REQUEST:
      case ActivityMemberSubject.MEMBER_ADDED:
      case ActivityMemberSubject.MEMBER_INVITED:
      case ActivityMemberSubject.MEMBER_ACCEPTED_INVITATION:
        return "account-multiple-plus";
      case ActivityMemberSubject.MEMBER_REMOVED:
      case ActivityMemberSubject.MEMBER_REJECTED_INVITATION:
      case ActivityMemberSubject.MEMBER_QUIT:
        return "account-multiple-minus";
      case ActivityMemberSubject.MEMBER_UPDATED:
      default:
        return "account-multiple";
    }
  }

  get iconColor(): string | undefined {
    switch (this.activity.subject) {
      case ActivityMemberSubject.MEMBER_ADDED:
      case ActivityMemberSubject.MEMBER_INVITED:
      case ActivityMemberSubject.MEMBER_JOINED:
      case ActivityMemberSubject.MEMBER_APPROVED:
      case ActivityMemberSubject.MEMBER_ACCEPTED_INVITATION:
        return "is-success";
      case ActivityMemberSubject.MEMBER_REQUEST:
      case ActivityMemberSubject.MEMBER_UPDATED:
        return "is-grey";
      case ActivityMemberSubject.MEMBER_REMOVED:
      case ActivityMemberSubject.MEMBER_REJECTED_INVITATION:
      case ActivityMemberSubject.MEMBER_QUIT:
        return "is-danger";
      default:
        return undefined;
    }
  }

  get isObjectMemberCurrentActor(): boolean {
    return (
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      this.activity?.object?.actor?.id === this.currentActor?.id &&
      this.currentActor?.id !== undefined
    );
  }
}
</script>
<style lang="scss" scoped>
@import "./activity.scss";
</style>
