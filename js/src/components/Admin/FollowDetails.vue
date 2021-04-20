<template>
  <div>
    <pre>{{ relayFollow }}</pre>
  </div>
</template>
<script lang="ts">
import { RELAY_FOLLOW } from "@/graphql/admin";
import { IFollower } from "@/types/actor/follower.model";
import { Component, Vue } from "vue-property-decorator";

@Component({
  apollo: {
    relayFollow: {
      query: RELAY_FOLLOW,
      variables() {
        return {
          id: this.$route.params.id,
        };
      },
    },
  },
})
export default class FollowDetails extends Vue {
  relayFollow!: IFollower;
}
</script>
