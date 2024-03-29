import { mixins } from "vue-class-component";
import { Component, Vue } from "vue-property-decorator";
import { SnackbarProgrammatic as Snackbar } from "buefy";
import { ParticipantRole } from "@/types/enums";
import { IParticipant } from "../types/participant.model";
import { IEvent } from "../types/event.model";
import {
  DELETE_EVENT,
  EVENT_PERSON_PARTICIPATION,
  FETCH_EVENT,
  LEAVE_EVENT,
} from "../graphql/event";
import { IPerson } from "../types/actor";
import { ApolloCache, FetchResult, InMemoryCache } from "@apollo/client/core";

@Component
export default class EventMixin extends mixins(Vue) {
  protected async leaveEvent(
    event: IEvent,
    actorId: string,
    token: string | null = null,
    anonymousParticipationConfirmed: boolean | null = null
  ): Promise<void> {
    try {
      const { data: resultData } = await this.$apollo.mutate<{
        leaveEvent: IParticipant;
      }>({
        mutation: LEAVE_EVENT,
        variables: {
          eventId: event.id,
          actorId,
          token,
        },
        update: (
          store: ApolloCache<{
            leaveEvent: IParticipant;
          }>,
          { data }: FetchResult
        ) => {
          if (data == null) return;
          let participation;

          if (!token) {
            const participationCachedData = store.readQuery<{
              person: IPerson;
            }>({
              query: EVENT_PERSON_PARTICIPATION,
              variables: { eventId: event.id, actorId },
            });
            if (participationCachedData == null) return;
            const { person } = participationCachedData;
            [participation] = person.participations.elements;

            store.modify({
              id: `Person:${actorId}`,
              fields: {
                participations() {
                  return {
                    elements: [],
                    total: 0,
                  };
                },
              },
            });
          }

          const eventCachedData = store.readQuery<{ event: IEvent }>({
            query: FETCH_EVENT,
            variables: { uuid: event.uuid },
          });
          if (eventCachedData == null) return;
          const { event: eventCached } = eventCachedData;
          if (eventCached === null) {
            console.error("Cannot update event cache, because of null value.");
            return;
          }
          const participantStats = { ...eventCached.participantStats };
          if (
            participation &&
            participation?.role === ParticipantRole.NOT_APPROVED
          ) {
            participantStats.notApproved -= 1;
          } else if (anonymousParticipationConfirmed === false) {
            participantStats.notConfirmed -= 1;
          } else {
            participantStats.going -= 1;
            participantStats.participant -= 1;
          }
          store.writeQuery({
            query: FETCH_EVENT,
            variables: { uuid: event.uuid },
            data: {
              event: {
                ...eventCached,
                participantStats,
              },
            },
          });
        },
      });
      if (resultData) {
        this.participationCancelledMessage();
      }
    } catch (error: any) {
      Snackbar.open({
        message: error.message,
        type: "is-danger",
        position: "is-bottom",
      });
      console.error(error);
    }
  }

  private participationCancelledMessage() {
    this.$notifier.success(
      this.$t("You have cancelled your participation") as string
    );
  }

  protected async openDeleteEventModal(event: IEvent): Promise<void> {
    function escapeRegExp(string: string) {
      return string.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"); // $& means the whole matched string
    }
    const participantsLength = event.participantStats.participant;
    const prefix = participantsLength
      ? this.$tc(
          "There are {participants} participants.",
          event.participantStats.participant,
          {
            participants: event.participantStats.participant,
          }
        )
      : "";

    this.$buefy.dialog.prompt({
      type: "is-danger",
      title: this.$t("Delete event") as string,
      message: `${prefix}
        ${this.$t(
          "Are you sure you want to delete this event? This action cannot be reverted."
        )}
        <br><br>
        ${this.$t('To confirm, type your event title "{eventTitle}"', {
          eventTitle: event.title,
        })}`,
      confirmText: this.$t("Delete {eventTitle}", {
        eventTitle: event.title,
      }) as string,
      inputAttrs: {
        placeholder: event.title,
        pattern: escapeRegExp(event.title),
      },
      onConfirm: () => this.deleteEvent(event),
    });
  }

  private async deleteEvent(event: IEvent) {
    const { title: eventTitle, id: eventId } = event;

    try {
      await this.$apollo.mutate<IParticipant>({
        mutation: DELETE_EVENT,
        variables: {
          eventId: event.id,
        },
      });
      const cache = this.$apollo.getClient().cache as InMemoryCache;
      cache.evict({ id: `Event:${eventId}` });
      cache.gc();
      /**
       * When the event corresponding has been deleted (by the organizer).
       * A notification is already triggered.
       *
       * @type {string}
       */
      this.$emit("event-deleted", event.id);

      this.$buefy.notification.open({
        message: this.$t("Event {eventTitle} deleted", {
          eventTitle,
        }) as string,
        type: "is-success",
        position: "is-bottom-right",
        duration: 5000,
      });
    } catch (error: any) {
      Snackbar.open({
        message: error.message,
        type: "is-danger",
        position: "is-bottom",
      });

      console.error(error);
    }
  }
}
