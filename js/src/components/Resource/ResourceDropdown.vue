<template>
  <b-dropdown aria-role="list" position="is-bottom-left">
    <mdicon name="dots-horizontal" slot="trigger" />

    <b-dropdown-item aria-role="listitem" @click="$emit('rename')">
      <mdicon name="pencil" />
      {{ $t("Rename") }}
    </b-dropdown-item>
    <b-dropdown-item aria-role="listitem" @click="$emit('move')">
      <mdicon name="folder-move" />
      {{ $t("Move") }}
    </b-dropdown-item>
    <b-dropdown-item aria-role="listitem" @click="$emit('delete')">
      <mdicon name="delete" />
      {{ $t("Delete") }}
    </b-dropdown-item>
  </b-dropdown>
</template>
<script lang="ts">
import { Component, Vue } from "vue-property-decorator";

@Component
export default class ResourceDropdown extends Vue {}
</script>
