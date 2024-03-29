<template>
  <div v-if="resource">
    <article class="panel is-primary">
      <p class="panel-heading">
        {{
          $t('Move "{resourceName}"', { resourceName: initialResource.title })
        }}
      </p>
      <a
        class="panel-block clickable"
        @click="resource = resource.parent"
        v-if="resource.parent"
      >
        <span class="panel-icon">
          <b-icon icon="chevron-up" size="is-small" />
        </span>
        {{ $t("Parent folder") }}
      </a>
      <a
        class="panel-block clickable"
        @click="resource = { path: '/', username }"
        v-else-if="resource.path.length > 1"
      >
        <span class="panel-icon">
          <b-icon icon="chevron-up" size="is-small" />
        </span>
        {{ $t("Parent folder") }}
      </a>
      <template v-if="resource.children">
        <a
          class="panel-block"
          v-for="element in resource.children.elements"
          :class="{
            clickable:
              element.type === 'folder' && element.id !== initialResource.id,
          }"
          :key="element.id"
          @click="goDown(element)"
        >
          <span class="panel-icon">
            <b-icon
              icon="folder"
              size="is-small"
              v-if="element.type === 'folder'"
            />
            <b-icon icon="link" size="is-small" v-else />
          </span>
          {{ element.title }}
          <span v-if="element.id === initialResource.id">
            <em v-if="element.type === 'folder'"> {{ $t("(this folder)") }}</em>
            <em v-else> {{ $t("(this link)") }}</em>
          </span>
        </a>
      </template>
      <p
        class="panel-block content has-text-grey has-text-centered"
        v-if="resource.children && resource.children.total === 0"
      >
        {{ $t("No resources in this folder") }}
      </p>
      <b-pagination
        v-if="resource.children && resource.children.total > RESOURCES_PER_PAGE"
        :total="resource.children.total"
        v-model="page"
        size="is-small"
        :per-page="RESOURCES_PER_PAGE"
        :aria-next-label="$t('Next page')"
        :aria-previous-label="$t('Previous page')"
        :aria-page-label="$t('Page')"
        :aria-current-label="$t('Current page')"
      />
    </article>
    <div class="buttons">
      <b-button type="is-text" @click="$emit('close-move-modal')">{{
        $t("Cancel")
      }}</b-button>
      <b-button
        type="is-primary"
        @click="updateResource"
        :disabled="moveDisabled"
        ><template v-if="resource.path === '/'">
          {{ $t("Move resource to the root folder") }}
        </template>
        <template v-else
          >{{ $t("Move resource to {folder}", { folder: resource.title }) }}
        </template></b-button
      >
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Prop } from "vue-property-decorator";
import { GET_RESOURCE } from "../../graphql/resources";
import { IResource } from "../../types/resource";

@Component({
  apollo: {
    resource: {
      query: GET_RESOURCE,
      variables() {
        if (this.resource && this.resource.path) {
          return {
            path: this.resource.path,
            username: this.username,
            page: this.page,
            limit: this.RESOURCES_PER_PAGE,
          };
        }
        return { path: "/", username: this.username };
      },
      skip() {
        return !this.username;
      },
    },
  },
})
export default class ResourceSelector extends Vue {
  @Prop({ required: true }) initialResource!: IResource;

  @Prop({ required: true }) username!: string;

  resource: IResource | undefined = this.initialResource.parent;

  RESOURCES_PER_PAGE = 10;

  page = 1;

  goDown(element: IResource): void {
    if (element.type === "folder" && element.id !== this.initialResource.id) {
      this.resource = element;
    }
  }

  updateResource(): void {
    this.$emit(
      "update-resource",
      {
        id: this.initialResource.id,
        title: this.initialResource.title,
        parent:
          this.resource && this.resource.path === "/" ? null : this.resource,
        path: this.initialResource.path,
      },
      this.initialResource.parent
    );
  }

  get moveDisabled(): boolean | undefined {
    return (
      (this.initialResource.parent &&
        this.resource &&
        this.initialResource.parent.path === this.resource.path) ||
      (this.initialResource.parent === undefined &&
        this.resource &&
        this.resource.path === "/")
    );
  }
}
</script>
<style lang="scss" scoped>
.panel {
  a.panel-block {
    cursor: default;

    &.clickable {
      cursor: pointer;
    }
  }

  &.is-primary .panel-heading {
    background: $primary;
    color: #fff;
  }
}
.buttons {
  justify-content: flex-end;
}

nav.pagination {
  margin: 0.5rem;
}
</style>
