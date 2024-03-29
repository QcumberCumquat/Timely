<template>
  <div class="container">
    <b-loading :active.sync="$apollo.queries.event.loading" />
    <div class="wrapper">
      <event-banner :picture="event.picture" />
      <div class="intro-wrapper">
        <div class="date-calendar-icon-wrapper">
          <date-calendar-icon :date="event.beginsOn" />
        </div>
        <section class="intro" dir="auto">
          <div class="columns">
            <div class="column">
              <h1 class="title" style="margin: 0" dir="auto">
                {{ event.title }}
              </h1>
              <div class="organizer">
                <div v-if="event.organizerActor && !event.attributedTo">
                  <popover-actor-card
                    :actor="event.organizerActor"
                    :inline="true"
                  >
                    <i18n path="By {username}" dir="auto">
                      <span dir="ltr" slot="username"
                        >@{{ usernameWithDomain(event.organizerActor) }}</span
                      >
                    </i18n>
                  </popover-actor-card>
                </div>
                <span v-else-if="event.attributedTo">
                  <popover-actor-card
                    :actor="event.attributedTo"
                    :inline="true"
                  >
                    <i18n path="By {group}" dir="auto">
                      <span dir="ltr" slot="group"
                        >@{{ usernameWithDomain(event.attributedTo) }}</span
                      >
                    </i18n>
                  </popover-actor-card>
                </span>
              </div>
              <p
                class="tags"
                v-if="event.tags && event.tags.length > 0"
                dir="auto"
              >
                <router-link
                  v-for="tag in event.tags"
                  :key="tag.title"
                  :to="{ name: RouteName.TAG, params: { tag: tag.title } }"
                >
                  <tag>{{ tag.title }}</tag>
                </router-link>
              </p>
              <b-tag type="is-warning" size="is-medium" v-if="event.draft"
                >{{ $t("Draft") }}
              </b-tag>
              <span
                class="event-status"
                v-if="event.status !== EventStatus.CONFIRMED"
              >
                <b-tag
                  type="is-warning"
                  v-if="event.status === EventStatus.TENTATIVE"
                  >{{ $t("Event to be confirmed") }}</b-tag
                >
                <b-tag
                  type="is-danger"
                  v-if="event.status === EventStatus.CANCELLED"
                  >{{ $t("Event cancelled") }}</b-tag
                >
              </span>
            </div>
            <div class="column is-3-tablet">
              <participation-section
                :participation="participations[0]"
                :event="event"
                :anonymousParticipation="anonymousParticipation"
                @join-event="joinEvent"
                @join-modal="isJoinModalActive = true"
                @join-event-with-confirmation="joinEventWithConfirmation"
                @confirm-leave="confirmLeave"
                @cancel-anonymous-participation="cancelAnonymousParticipation"
              />
              <div class="has-text-right">
                <template class="visibility" v-if="!event.draft">
                  <p v-if="event.visibility === EventVisibility.PUBLIC">
                    {{ $t("Public event") }}
                    <b-icon icon="earth" />
                  </p>
                  <p v-if="event.visibility === EventVisibility.UNLISTED">
                    {{ $t("Private event") }}
                    <b-icon icon="link" />
                  </p>
                </template>
                <template v-if="!event.local && organizer.domain">
                  <a :href="event.url">
                    <tag>{{ organizer.domain }}</tag>
                  </a>
                </template>
                <p>
                  <router-link
                    class="participations-link"
                    v-if="canManageEvent && event.draft === false"
                    :to="{
                      name: RouteName.PARTICIPATIONS,
                      params: { eventId: event.uuid },
                    }"
                  >
                    <!-- We retire one because of the event creator who is a participant -->
                    <span v-if="maximumAttendeeCapacity">
                      {{
                        $tc(
                          "{available}/{capacity} available places",
                          maximumAttendeeCapacity -
                            event.participantStats.participant,
                          {
                            available:
                              maximumAttendeeCapacity -
                              event.participantStats.participant,
                            capacity: maximumAttendeeCapacity,
                          }
                        )
                      }}
                    </span>
                    <span v-else>
                      {{
                        $tc(
                          "No one is participating|One person participating|{going} people participating",
                          event.participantStats.participant,
                          {
                            going: event.participantStats.participant,
                          }
                        )
                      }}
                    </span>
                  </router-link>
                  <span v-else>
                    <span v-if="maximumAttendeeCapacity">
                      {{
                        $tc(
                          "{available}/{capacity} available places",
                          maximumAttendeeCapacity -
                            event.participantStats.participant,
                          {
                            available:
                              maximumAttendeeCapacity -
                              event.participantStats.participant,
                            capacity: maximumAttendeeCapacity,
                          }
                        )
                      }}
                    </span>
                    <span v-else>
                      {{
                        $tc(
                          "No one is participating|One person participating|{going} people participating",
                          event.participantStats.participant,
                          {
                            going: event.participantStats.participant,
                          }
                        )
                      }}
                    </span>
                  </span>
                  <b-tooltip
                    type="is-dark"
                    v-if="!event.local"
                    :label="
                      $t(
                        'The actual number of participants may differ, as this event is hosted on another instance.'
                      )
                    "
                  >
                    <b-icon size="is-small" icon="help-circle-outline" />
                  </b-tooltip>
                  <b-icon icon="ticket-confirmation-outline" />
                </p>
                <b-dropdown position="is-bottom-left" aria-role="list">
                  <b-button
                    slot="trigger"
                    role="button"
                    icon-right="dots-horizontal"
                  >
                    {{ $t("Actions") }}
                  </b-button>
                  <b-dropdown-item
                    aria-role="listitem"
                    has-link
                    v-if="canManageEvent || event.draft"
                  >
                    <router-link
                      :to="{
                        name: RouteName.EDIT_EVENT,
                        params: { eventId: event.uuid },
                      }"
                    >
                      {{ $t("Edit") }}
                      <b-icon icon="pencil" />
                    </router-link>
                  </b-dropdown-item>
                  <b-dropdown-item
                    aria-role="listitem"
                    has-link
                    v-if="canManageEvent || event.draft"
                  >
                    <router-link
                      :to="{
                        name: RouteName.DUPLICATE_EVENT,
                        params: { eventId: event.uuid },
                      }"
                    >
                      {{ $t("Duplicate") }}
                      <b-icon icon="content-duplicate" />
                    </router-link>
                  </b-dropdown-item>
                  <b-dropdown-item
                    aria-role="listitem"
                    v-if="canManageEvent || event.draft"
                    @click="openDeleteEventModalWrapper"
                    @keyup.enter="openDeleteEventModalWrapper"
                  >
                    {{ $t("Delete") }}
                    <b-icon icon="delete" />
                  </b-dropdown-item>

                  <hr
                    role="presentation"
                    class="dropdown-divider"
                    aria-role="menuitem"
                    v-if="canManageEvent || event.draft"
                  />
                  <b-dropdown-item
                    aria-role="listitem"
                    v-if="!event.draft"
                    @click="triggerShare()"
                    @keyup.enter="triggerShare()"
                  >
                    <span>
                      {{ $t("Share this event") }}
                      <b-icon icon="share" />
                    </span>
                  </b-dropdown-item>
                  <b-dropdown-item
                    aria-role="listitem"
                    @click="downloadIcsEvent()"
                    @keyup.enter="downloadIcsEvent()"
                    v-if="!event.draft"
                  >
                    <span>
                      {{ $t("Add to my calendar") }}
                      <b-icon icon="calendar-plus" />
                    </span>
                  </b-dropdown-item>
                  <b-dropdown-item
                    aria-role="listitem"
                    v-if="ableToReport"
                    @click="isReportModalActive = true"
                    @keyup.enter="isReportModalActive = true"
                  >
                    <span>
                      {{ $t("Report") }}
                      <b-icon icon="flag" />
                    </span>
                  </b-dropdown-item>
                </b-dropdown>
              </div>
            </div>
          </div>
        </section>
      </div>
      <div class="event-description-wrapper">
        <aside class="event-metadata">
          <div class="sticky">
            <event-metadata-sidebar
              v-if="event && config"
              :event="event"
              :config="config"
              :user="loggedUser"
              @showMapModal="showMap = true"
            />
          </div>
        </aside>
        <div class="event-description-comments">
          <section class="event-description">
            <subtitle>{{ $t("About this event") }}</subtitle>
            <p v-if="!event.description">
              {{ $t("The event organizer didn't add any description.") }}
            </p>
            <div v-else>
              <div
                dir="auto"
                class="description-content"
                ref="eventDescriptionElement"
                v-html="event.description"
              />
            </div>
          </section>
          <section class="integration-wrappers">
            <component
              v-for="(metadata, integration) in integrations"
              :is="integration"
              :key="integration"
              :metadata="metadata"
            />
          </section>
          <section class="comments" ref="commentsObserver">
            <a href="#comments">
              <subtitle id="comments">{{ $t("Comments") }}</subtitle>
            </a>
            <comment-tree v-if="loadComments" :event="event" />
          </section>
        </div>
      </div>
      <section
        class="more-events section"
        v-if="event.relatedEvents.length > 0"
      >
        <h3 class="title has-text-centered">
          {{ $t("These events may interest you") }}
        </h3>
        <multi-card :events="event.relatedEvents" />
      </section>
      <b-modal
        :active.sync="isReportModalActive"
        has-modal-card
        ref="reportModal"
      >
        <report-modal
          :on-confirm="reportEvent"
          :title="$t('Report this event')"
          :outside-domain="organizerDomain"
          @close="$refs.reportModal.close()"
        />
      </b-modal>
      <b-modal
        :active.sync="isShareModalActive"
        has-modal-card
        ref="shareModal"
      >
        <share-event-modal :event="event" :eventCapacityOK="eventCapacityOK" />
      </b-modal>
      <b-modal
        :active.sync="isJoinModalActive"
        has-modal-card
        ref="participationModal"
      >
        <identity-picker v-model="identity">
          <template v-slot:footer>
            <footer class="modal-card-foot">
              <button
                class="button"
                ref="cancelButton"
                @click="isJoinModalActive = false"
                @keyup.enter="isJoinModalActive = false"
              >
                {{ $t("Cancel") }}
              </button>
              <button
                class="button is-primary"
                ref="confirmButton"
                @click="
                  event.joinOptions === EventJoinOptions.RESTRICTED
                    ? joinEventWithConfirmation(identity)
                    : joinEvent(identity)
                "
                @keyup.enter="
                  event.joinOptions === EventJoinOptions.RESTRICTED
                    ? joinEventWithConfirmation(identity)
                    : joinEvent(identity)
                "
              >
                {{ $t("Confirm my particpation") }}
              </button>
            </footer>
          </template>
        </identity-picker>
      </b-modal>
      <b-modal
        :active.sync="isJoinConfirmationModalActive"
        has-modal-card
        ref="joinConfirmationModal"
      >
        <div class="modal-card">
          <header class="modal-card-head">
            <p class="modal-card-title">
              {{ $t("Participation confirmation") }}
            </p>
          </header>

          <section class="modal-card-body">
            <p>
              {{
                $t(
                  "The event organiser has chosen to validate manually participations. Do you want to add a little note to explain why you want to participate to this event?"
                )
              }}
            </p>
            <form
              @submit.prevent="
                joinEvent(actorForConfirmation, messageForConfirmation)
              "
            >
              <b-field :label="$t('Message')">
                <b-input
                  type="textarea"
                  size="is-medium"
                  v-model="messageForConfirmation"
                  minlength="10"
                ></b-input>
              </b-field>
              <div class="buttons">
                <b-button
                  native-type="button"
                  class="button"
                  ref="cancelButton"
                  @click="isJoinConfirmationModalActive = false"
                  @keyup.enter="isJoinConfirmationModalActive = false"
                  >{{ $t("Cancel") }}
                </b-button>
                <b-button type="is-primary" native-type="submit">
                  {{ $t("Confirm my participation") }}
                </b-button>
              </div>
            </form>
          </section>
        </div>
      </b-modal>
      <b-modal
        class="map-modal"
        v-if="event.physicalAddress && event.physicalAddress.geom"
        :active.sync="showMap"
        has-modal-card
        full-screen
        :can-cancel="['escape', 'outside']"
      >
        <template #default="props">
          <event-map
            :routingType="routingType"
            :address="event.physicalAddress"
            @close="props.close"
          />
        </template>
      </b-modal>
    </div>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Watch } from "vue-property-decorator";
import BIcon from "buefy/src/components/icon/Icon.vue";
import {
  EventJoinOptions,
  EventStatus,
  EventVisibility,
  MemberRole,
  ParticipantRole,
} from "@/types/enums";
import {
  EVENT_PERSON_PARTICIPATION,
  EVENT_PERSON_PARTICIPATION_SUBSCRIPTION_CHANGED,
  FETCH_EVENT,
  JOIN_EVENT,
} from "../../graphql/event";
import { CURRENT_ACTOR_CLIENT, PERSON_STATUS_GROUP } from "../../graphql/actor";
import { EventModel, IEvent } from "../../types/event.model";
import { IActor, IPerson, Person, usernameWithDomain } from "../../types/actor";
import { GRAPHQL_API_ENDPOINT } from "../../api/_entrypoint";
import DateCalendarIcon from "../../components/Event/DateCalendarIcon.vue";
import MultiCard from "../../components/Event/MultiCard.vue";
import ReportModal from "../../components/Report/ReportModal.vue";
import { IReport } from "../../types/report.model";
import { CREATE_REPORT } from "../../graphql/report";
import EventMixin from "../../mixins/event";
import IdentityPicker from "../Account/IdentityPicker.vue";
import ParticipationSection from "../../components/Participation/ParticipationSection.vue";
import RouteName from "../../router/name";
import CommentTree from "../../components/Comment/CommentTree.vue";
import "intersection-observer";
import { CONFIG } from "../../graphql/config";
import {
  AnonymousParticipationNotFoundError,
  getLeaveTokenForParticipation,
  isParticipatingInThisEvent,
  removeAnonymousParticipation,
} from "../../services/AnonymousParticipationStorage";
import { IConfig } from "../../types/config.model";
import Subtitle from "../../components/Utils/Subtitle.vue";
import Tag from "../../components/Tag.vue";
import EventMetadataSidebar from "../../components/Event/EventMetadataSidebar.vue";
import EventBanner from "../../components/Event/EventBanner.vue";
import EventMap from "../../components/Event/EventMap.vue";
import PopoverActorCard from "../../components/Account/PopoverActorCard.vue";
import { IParticipant } from "../../types/participant.model";
import { ApolloCache, FetchResult } from "@apollo/client/core";
import { IEventMetadataDescription } from "@/types/event-metadata";
import { eventMetaDataList } from "../../services/EventMetadata";
import { USER_SETTINGS } from "@/graphql/user";
import { IUser } from "@/types/current-user.model";

// noinspection TypeScriptValidateTypes
@Component({
  components: {
    Subtitle,
    MultiCard,
    BIcon,
    DateCalendarIcon,
    ReportModal,
    IdentityPicker,
    ParticipationSection,
    CommentTree,
    Tag,
    PopoverActorCard,
    EventBanner,
    EventMetadataSidebar,
    EventMap,
    ShareEventModal: () =>
      import(
        /* webpackChunkName: "shareEventModal" */ "../../components/Event/ShareEventModal.vue"
      ),
    "integration-twitch": () =>
      import(
        /* webpackChunkName: "twitchIntegration" */ "../../components/Event/Integrations/Twitch.vue"
      ),
    "integration-peertube": () =>
      import(
        /* webpackChunkName: "PeerTubeIntegration" */ "../../components/Event/Integrations/PeerTube.vue"
      ),
    "integration-youtube": () =>
      import(
        /* webpackChunkName: "YouTubeIntegration" */ "../../components/Event/Integrations/YouTube.vue"
      ),
    "integration-jitsi-meet": () =>
      import(
        /* webpackChunkName: "JitsiMeetIntegration" */ "../../components/Event/Integrations/JitsiMeet.vue"
      ),
    "integration-etherpad": () =>
      import(
        /* webpackChunkName: "EtherpadIntegration" */ "../../components/Event/Integrations/Etherpad.vue"
      ),
  },
  apollo: {
    event: {
      query: FETCH_EVENT,
      variables() {
        return {
          uuid: this.uuid,
        };
      },
      error({ graphQLErrors }) {
        this.handleErrors(graphQLErrors);
      },
    },
    currentActor: CURRENT_ACTOR_CLIENT,
    loggedUser: USER_SETTINGS,
    participations: {
      query: EVENT_PERSON_PARTICIPATION,
      variables() {
        return {
          eventId: this.event.id,
          actorId: this.currentActor.id,
        };
      },
      subscribeToMore: {
        document: EVENT_PERSON_PARTICIPATION_SUBSCRIPTION_CHANGED,
        variables() {
          return {
            eventId: this.event.id,
            actorId: this.currentActor.id,
          };
        },
      },
      update: (data) => {
        if (data && data.person) return data.person.participations.elements;
        return [];
      },
      skip() {
        return (
          !this.currentActor ||
          !this.event ||
          !this.event.id ||
          !this.currentActor.id
        );
      },
    },
    person: {
      query: PERSON_STATUS_GROUP,
      variables() {
        return {
          id: this.currentActor.id,
          group: usernameWithDomain(this.event?.attributedTo),
        };
      },
      skip() {
        return (
          !this.currentActor.id ||
          !this.event?.attributedTo ||
          !this.event?.attributedTo?.preferredUsername
        );
      },
    },
    config: CONFIG,
  },
  metaInfo() {
    return {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      title: this.eventTitle,
      meta: [
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        { name: "description", content: this.eventDescription },
      ],
    };
  },
})
export default class Event extends EventMixin {
  @Prop({ type: String, required: true }) uuid!: string;

  event: IEvent = new EventModel();

  currentActor!: IPerson;

  identity: IPerson = new Person();

  config!: IConfig;

  person!: IPerson;

  loggedUser!: IUser;

  participations: IParticipant[] = [];

  oldParticipationRole!: string;

  isReportModalActive = false;

  isShareModalActive = false;

  isJoinModalActive = false;

  isJoinConfirmationModalActive = false;

  EventVisibility = EventVisibility;

  EventStatus = EventStatus;

  EventJoinOptions = EventJoinOptions;

  usernameWithDomain = usernameWithDomain;

  RouteName = RouteName;

  observer!: IntersectionObserver;

  loadComments = false;

  anonymousParticipation: boolean | null = null;

  actorForConfirmation!: IPerson;

  messageForConfirmation = "";

  get eventTitle(): undefined | string {
    if (!this.event) return undefined;
    return this.event.title;
  }

  get eventDescription(): undefined | string {
    if (!this.event) return undefined;
    return this.event.description;
  }

  async mounted(): Promise<void> {
    this.identity = this.currentActor;
    if (this.$route.hash.includes("#comment-")) {
      this.loadComments = true;
    }

    try {
      if (window.isSecureContext) {
        this.anonymousParticipation =
          await this.anonymousParticipationConfirmed();
      }
    } catch (e) {
      if (e instanceof AnonymousParticipationNotFoundError) {
        this.anonymousParticipation = null;
      } else {
        console.error(e);
      }
    }

    this.observer = new IntersectionObserver(
      (entries) => {
        // eslint-disable-next-line no-restricted-syntax
        for (const entry of entries) {
          if (entry) {
            this.loadComments = entry.isIntersecting || this.loadComments;
          }
        }
      },
      {
        rootMargin: "-50px 0px -50px",
      }
    );
    this.observer.observe(this.$refs.commentsObserver as Element);

    this.$watch("eventDescription", (eventDescription) => {
      if (!eventDescription) return;
      const eventDescriptionElement = this.$refs
        .eventDescriptionElement as HTMLElement;

      eventDescriptionElement.addEventListener("click", ($event) => {
        // TODO: Find the right type for target
        let { target }: { target: any } = $event;
        while (target && target.tagName !== "A") target = target.parentNode;
        // handle only links that occur inside the component and do not reference external resources
        if (target && target.matches(".hashtag") && target.href) {
          // some sanity checks taken from vue-router:
          // https://github.com/vuejs/vue-router/blob/dev/src/components/link.js#L106
          const {
            altKey,
            ctrlKey,
            metaKey,
            shiftKey,
            button,
            defaultPrevented,
          } = $event;
          // don't handle with control keys
          if (metaKey || altKey || ctrlKey || shiftKey) return;
          // don't handle when preventDefault called
          if (defaultPrevented) return;
          // don't handle right clicks
          if (button !== undefined && button !== 0) return;
          // don't handle if `target="_blank"`
          if (target && target.getAttribute) {
            const linkTarget = target.getAttribute("target");
            if (/\b_blank\b/i.test(linkTarget)) return;
          }
          // don't handle same page links/anchors
          const url = new URL(target.href);
          const to = url.pathname;
          if (window.location.pathname !== to && $event.preventDefault) {
            $event.preventDefault();
            this.$router.push(to);
          }
        }
      });
    });

    this.$on("event-deleted", () => {
      return this.$router.push({ name: RouteName.HOME });
    });
  }

  /**
   * Delete the event, then redirect to home.
   */
  async openDeleteEventModalWrapper(): Promise<void> {
    await this.openDeleteEventModal(this.event);
  }

  async reportEvent(content: string, forward: boolean): Promise<void> {
    this.isReportModalActive = false;
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    this.$refs.reportModal.close();
    if (!this.organizer) return;
    const eventTitle = this.event.title;

    try {
      await this.$apollo.mutate<IReport>({
        mutation: CREATE_REPORT,
        variables: {
          eventId: this.event.id,
          reportedId: this.organizer ? this.organizer.id : null,
          content,
          forward,
        },
      });
      this.$notifier.success(
        this.$t("Event {eventTitle} reported", { eventTitle }) as string
      );
    } catch (error) {
      console.error(error);
    }
  }

  joinEventWithConfirmation(actor: IPerson): void {
    this.isJoinConfirmationModalActive = true;
    this.actorForConfirmation = actor;
  }

  async joinEvent(
    identity: IPerson,
    message: string | null = null
  ): Promise<void> {
    this.isJoinConfirmationModalActive = false;
    this.isJoinModalActive = false;
    try {
      const { data: mutationData } = await this.$apollo.mutate<{
        joinEvent: IParticipant;
      }>({
        mutation: JOIN_EVENT,
        variables: {
          eventId: this.event.id,
          actorId: identity.id,
          message,
        },
        update: (
          store: ApolloCache<{
            joinEvent: IParticipant;
          }>,
          { data }: FetchResult
        ) => {
          if (data == null) return;

          const participationCachedData = store.readQuery<{ person: IPerson }>({
            query: EVENT_PERSON_PARTICIPATION,
            variables: { eventId: this.event.id, actorId: identity.id },
          });

          if (participationCachedData?.person == undefined) {
            console.error(
              "Cannot update participation cache, because of null value."
            );
            return;
          }
          store.writeQuery({
            query: EVENT_PERSON_PARTICIPATION,
            variables: { eventId: this.event.id, actorId: identity.id },
            data: {
              person: {
                ...participationCachedData?.person,
                participations: {
                  elements: [data.joinEvent],
                  total: 1,
                },
              },
            },
          });

          const cachedData = store.readQuery<{ event: IEvent }>({
            query: FETCH_EVENT,
            variables: { uuid: this.event.uuid },
          });
          if (cachedData == null) return;
          const { event } = cachedData;
          if (event === null) {
            console.error(
              "Cannot update event participant cache, because of null value."
            );
            return;
          }
          const participantStats = { ...event.participantStats };

          if (data.joinEvent.role === ParticipantRole.NOT_APPROVED) {
            participantStats.notApproved += 1;
          } else {
            participantStats.going += 1;
            participantStats.participant += 1;
          }

          store.writeQuery({
            query: FETCH_EVENT,
            variables: { uuid: this.uuid },
            data: {
              event: {
                ...event,
                participantStats,
              },
            },
          });
        },
      });
      if (mutationData) {
        if (mutationData.joinEvent.role === ParticipantRole.NOT_APPROVED) {
          this.participationRequestedMessage();
        } else {
          this.participationConfirmedMessage();
        }
      }
    } catch (error) {
      console.error(error);
    }
  }

  confirmLeave(): void {
    this.$buefy.dialog.confirm({
      title: this.$t('Leaving event "{title}"', {
        title: this.event.title,
      }) as string,
      message: this.$t(
        'Are you sure you want to cancel your participation at event "{title}"?',
        {
          title: this.event.title,
        }
      ) as string,
      confirmText: this.$t("Leave event") as string,
      cancelText: this.$t("Cancel") as string,
      type: "is-danger",
      hasIcon: true,
      onConfirm: () => {
        if (this.currentActor.id) {
          this.leaveEvent(this.event, this.currentActor.id);
        }
      },
    });
  }

  @Watch("participations")
  watchParticipations(): void {
    if (this.participations.length > 0) {
      if (
        this.oldParticipationRole &&
        this.participations[0].role !== ParticipantRole.NOT_APPROVED &&
        this.oldParticipationRole !== this.participations[0].role
      ) {
        switch (this.participations[0].role) {
          case ParticipantRole.PARTICIPANT:
            this.participationConfirmedMessage();
            break;
          case ParticipantRole.REJECTED:
            this.participationRejectedMessage();
            break;
          default:
            this.participationChangedMessage();
            break;
        }
      }
      this.oldParticipationRole = this.participations[0].role;
    }
  }

  private participationConfirmedMessage() {
    this.$notifier.success(
      this.$t("Your participation has been confirmed") as string
    );
  }

  private participationRequestedMessage() {
    this.$notifier.success(
      this.$t("Your participation has been requested") as string
    );
  }

  private participationRejectedMessage() {
    this.$notifier.error(
      this.$t("Your participation has been rejected") as string
    );
  }

  private participationChangedMessage() {
    this.$notifier.info(
      this.$t("Your participation status has been changed") as string
    );
  }

  async downloadIcsEvent(): Promise<void> {
    const data = await (
      await fetch(`${GRAPHQL_API_ENDPOINT}/events/${this.uuid}/export/ics`)
    ).text();
    const blob = new Blob([data], { type: "text/calendar" });
    const link = document.createElement("a");
    link.href = window.URL.createObjectURL(blob);
    link.download = `${this.event.title}.ics`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  triggerShare(): void {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore-start
    if (navigator.share) {
      navigator
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        .share({
          title: this.event.title,
          url: this.event.url,
        })
        .then(() => console.log("Successful share"))
        .catch((error: any) => console.log("Error sharing", error));
    } else {
      this.isShareModalActive = true;
      // send popup
    }
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore-end
  }

  handleErrors(errors: any[]): void {
    if (
      errors.some((error) => error.status_code === 404) ||
      errors.some(({ message }) => message.includes("has invalid value $uuid"))
    ) {
      this.$router.replace({ name: RouteName.PAGE_NOT_FOUND });
    }
  }

  get actorIsParticipant(): boolean {
    if (this.actorIsOrganizer) return true;

    return (
      this.participations.length > 0 &&
      this.participations[0].role === ParticipantRole.PARTICIPANT
    );
  }

  get actorIsOrganizer(): boolean {
    return (
      this.participations.length > 0 &&
      this.participations[0].role === ParticipantRole.CREATOR
    );
  }

  get hasGroupPrivileges(): boolean {
    return (
      this.person?.memberships?.total > 0 &&
      [MemberRole.MODERATOR, MemberRole.ADMINISTRATOR].includes(
        this.person?.memberships?.elements[0].role
      )
    );
  }

  get canManageEvent(): boolean {
    return this.actorIsOrganizer || this.hasGroupPrivileges;
  }

  get endDate(): Date {
    return this.event.endsOn !== null && this.event.endsOn > this.event.beginsOn
      ? this.event.endsOn
      : this.event.beginsOn;
  }

  get maximumAttendeeCapacity(): number {
    return this.event?.options?.maximumAttendeeCapacity;
  }

  get eventCapacityOK(): boolean {
    if (this.event.draft) return true;
    if (!this.maximumAttendeeCapacity) return true;
    return (
      this.event?.options?.maximumAttendeeCapacity >
      this.event.participantStats.participant
    );
  }

  get numberOfPlacesStillAvailable(): number {
    if (this.event.draft) return this.maximumAttendeeCapacity;
    return (
      this.maximumAttendeeCapacity - this.event.participantStats.participant
    );
  }

  async anonymousParticipationConfirmed(): Promise<boolean> {
    return isParticipatingInThisEvent(this.uuid);
  }

  async cancelAnonymousParticipation(): Promise<void> {
    const token = (await getLeaveTokenForParticipation(this.uuid)) as string;
    await this.leaveEvent(this.event, this.config.anonymous.actorId, token);
    await removeAnonymousParticipation(this.uuid);
    this.anonymousParticipation = null;
  }

  get ableToReport(): boolean {
    return (
      this.config &&
      (this.currentActor.id != null || this.config.anonymous.reports.allowed)
    );
  }

  get organizer(): IActor | null {
    if (this.event.attributedTo && this.event.attributedTo.id) {
      return this.event.attributedTo;
    }
    if (this.event.organizerActor) {
      return this.event.organizerActor;
    }
    return null;
  }

  get organizerDomain(): string | null {
    if (this.organizer) {
      return this.organizer.domain;
    }
    return null;
  }

  metadataToComponent: Record<string, string> = {
    "mz:live:twitch:url": "integration-twitch",
    "mz:live:peertube:url": "integration-peertube",
    "mz:live:youtube:url": "integration-youtube",
    "mz:visio:jitsi_meet": "integration-jitsi-meet",
    "mz:notes:etherpad:url": "integration-etherpad",
  };

  get integrations(): Record<string, IEventMetadataDescription> {
    return this.event.metadata
      .map((val) => {
        const def = eventMetaDataList.find((dat) => dat.key === val.key);
        return {
          ...def,
          ...val,
        };
      })
      .reduce((acc: Record<string, IEventMetadataDescription>, metadata) => {
        const component = this.metadataToComponent[metadata.key];
        if (component !== undefined) {
          // eslint-disable-next-line @typescript-eslint/ban-ts-comment
          // @ts-ignore
          acc[component] = metadata;
        }
        return acc;
      }, {});
  }

  showMap = false;

  get routingType(): string | undefined {
    return this.config?.maps?.routing?.type;
  }
}
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
.section {
  padding: 1rem 2rem 4rem;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.5s;
}

.fade-enter,
.fade-leave-to {
  opacity: 0;
}

div.sidebar {
  display: flex;
  flex-wrap: wrap;
  flex-direction: column;

  position: relative;

  &::before {
    content: "";
    background: #b3b3b2;
    position: absolute;
    bottom: 30px;
    top: 30px;
    left: 0;
    height: calc(100% - 60px);
    width: 1px;
  }

  div.organizer {
    display: inline-flex;
    padding-top: 10px;

    a {
      color: #4a4a4a;

      span {
        line-height: 2.7rem;
        @include padding-right(6px);
      }
    }
  }
}

.intro {
  background: white;

  .is-3-tablet {
    width: initial;
  }

  p.tags {
    a {
      text-decoration: none;
    }

    span {
      &.tag {
        margin: 0 2px;
      }
    }
  }
}

.event-description-wrapper {
  display: flex;
  flex-wrap: wrap;
  flex-direction: column;
  padding: 0;

  @media all and (min-width: 672px) {
    flex-direction: row-reverse;
  }

  & > aside,
  & > div {
    @media all and (min-width: 672px) {
      margin: 2rem auto;
    }
  }

  aside.event-metadata {
    min-width: 20rem;
    flex: 1;
    @media all and (min-width: 672px) {
      @include padding-left(1rem);
    }

    .sticky {
      position: sticky;
      background: white;
      top: 50px;
      padding: 1rem;
    }
  }

  div.event-description-comments {
    min-width: 20rem;
    padding: 1rem;
    flex: 2;
    background: white;
  }

  .description-content {
    ::v-deep h1 {
      font-size: 2rem;
    }

    ::v-deep h2 {
      font-size: 1.5rem;
    }

    ::v-deep h3 {
      font-size: 1.25rem;
    }

    ::v-deep ul {
      list-style-type: disc;
    }

    ::v-deep li {
      margin: 10px auto 10px 2rem;
    }

    ::v-deep blockquote {
      border-left: 0.2em solid #333;
      display: block;
      @include padding-left(1rem);
    }

    ::v-deep p {
      margin: 10px auto;

      a {
        display: inline-block;
        padding: 0.3rem;
        background: $secondary;
        color: #111;

        &:empty {
          display: none;
        }
      }
    }
  }
}

.comments {
  padding-top: 3rem;

  a h3#comments {
    margin-bottom: 10px;
  }
}

.more-events {
  background: white;
  padding: 1rem 1rem 4rem;

  & > .title {
    font-size: 1.5rem;
  }
}

.dropdown .dropdown-trigger span {
  cursor: pointer;
}

a.dropdown-item,
.dropdown .dropdown-menu .has-link a,
button.dropdown-item {
  white-space: nowrap;
  width: 100%;
  @include padding-right(1rem);
  text-align: right;
}

a.participations-link {
  text-decoration: none;
}

.event-status .tag {
  font-size: 1rem;
}

.no-border {
  border: 0;
  cursor: auto;
}

.wrapper,
.intro-wrapper {
  display: flex;
  flex-direction: column;
}

.intro-wrapper {
  position: relative;
  padding: 0 16px 16px;
  background: #fff;

  .date-calendar-icon-wrapper {
    margin-top: 16px;
    height: 0;
    display: flex;
    align-items: flex-end;
    align-self: flex-start;
    margin-bottom: 7px;
    @include margin-left(0);
  }
}
.title {
  margin: 0;
  font-size: 2rem;
}
</style>
