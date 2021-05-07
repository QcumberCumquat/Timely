import { IPatchedActivity } from "@/types/activity.model";
import {
  ActivityEventCommentSubject,
  ActivityEventSubject,
} from "@/types/enums";
import { IEvent } from "@/types/event.model";
import { convertActivityOptions } from "./utils";

export function convertEventActivity(
  activity: IPatchedActivity<IEvent>,
  options: convertActivityOptions
): string | undefined {
  switch (activity.subject) {
    case ActivityEventSubject.EVENT_CREATED:
      if (options.isAuthorCurrentActor) {
        return "You created the event {event}.";
      }
      return "The event {event} was created by {profile}.";
    case ActivityEventSubject.EVENT_UPDATED:
      if (options.isAuthorCurrentActor) {
        return "You updated the event {event}.";
      }
      return "The event {event} was updated by {profile}.";
    case ActivityEventSubject.EVENT_DELETED:
      if (options.isAuthorCurrentActor) {
        return "You deleted the event {event}.";
      }
      return "The event {event} was deleted by {profile}.";
    case ActivityEventCommentSubject.COMMENT_POSTED:
      if (activity.subjectParams.comment_reply_to) {
        if (options.isAuthorCurrentActor) {
          return "You replied to a comment on the event {event}.";
        }
        return "{profile} replied to a comment on the event {event}.";
      }
      if (options.isAuthorCurrentActor) {
        return "You posted a comment on the event {event}.";
      }
      return "{profile} posted a comment on the event {event}.";
    default:
      return undefined;
  }
}
