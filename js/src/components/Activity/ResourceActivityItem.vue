<template>
  <div class="activity-item">
    <b-icon :icon="'link'" :type="iconColor" />
    <div class="subject">
      <i18n :path="translation" tag="p">
        <router-link v-if="activity.object" slot="resource" :to="path">{{
          subjectParams.resource_title
        }}</router-link>
        <b v-else slot="resource">{{ subjectParams.resource_title }}</b>
        <router-link v-if="activity.object" slot="new_path" :to="path">{{
          parentDirectory
        }}</router-link>
        <b v-else slot="new_path">{{ parentDirectory }}</b>
        <router-link
          v-if="activity.object && subjectParams.old_resource_title"
          slot="old_resource_title"
          :to="path"
          >{{ subjectParams.old_resource_title }}</router-link
        >
        <b
          v-else-if="subjectParams.old_resource_title"
          slot="old_resource_title"
          >{{ subjectParams.old_resource_title }}</b
        >

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
import { ActivityResourceSubject } from "@/types/enums";
import { Component } from "vue-property-decorator";
import RouteName from "../../router/name";
import PopoverActorCard from "../Account/PopoverActorCard.vue";
import ActivityMixin from "../../mixins/activity";
import { mixins } from "vue-class-component";
import { Location } from "vue-router";
import { convertActivity } from "@/services/activity-converter";

@Component({
  components: {
    PopoverActorCard,
  },
})
export default class ResourceActivityItem extends mixins(ActivityMixin) {
  usernameWithDomain = usernameWithDomain;
  RouteName = RouteName;

  get translation(): string | undefined {
    return convertActivity(this.activity, {
      isAuthorCurrentActor: this.isAuthorCurrentActor,
      parentDirectory: this.parentDirectory,
    });
  }

  get iconColor(): string | undefined {
    switch (this.activity.subject) {
      case ActivityResourceSubject.RESOURCE_CREATED:
        return "is-success";
      case ActivityResourceSubject.RESOURCE_MOVED:
      case ActivityResourceSubject.RESOURCE_UPDATED:
        return "is-grey";
      case ActivityResourceSubject.RESOURCE_DELETED:
        return "is-danger";
      default:
        return undefined;
    }
  }

  get path(): Location {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    let path = this.parentPath(this.activity?.object?.path);
    if (path === "") {
      return {
        name: RouteName.RESOURCE_FOLDER_ROOT,
        params: {
          preferredUsername: usernameWithDomain(this.activity.group),
        },
      };
    }
    return {
      name: RouteName.RESOURCE_FOLDER,
      params: {
        path,
        preferredUsername: usernameWithDomain(this.activity.group),
      },
    };
  }

  get parentDirectory(): string | undefined | null {
    if (this.subjectParams.resource_path) {
      const parentPath = this.parentPath(this.subjectParams.resource_path);
      const directory = parentPath.split("/");
      return directory.pop();
    }
    return null;
  }

  parentPath(parent: string): string {
    let path = parent.split("/");
    path.pop();
    return path.join("/").replace(/^\//, "");
  }
}
</script>
<style lang="scss" scoped>
@import "./activity.scss";
</style>
