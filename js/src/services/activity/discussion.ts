import { IPatchedActivity } from "@/types/activity.model";
import { IDiscussion } from "@/types/discussions";
import { ActivityDiscussionSubject } from "@/types/enums";
import { convertActivityOptions } from "./utils";

export function convertDiscussionActivity(
  activity: IPatchedActivity<IDiscussion>,
  options: convertActivityOptions
): string | undefined {
  switch (activity.subject) {
    case ActivityDiscussionSubject.DISCUSSION_CREATED:
      if (options.isAuthorCurrentActor) {
        return "You created the discussion {discussion}.";
      }
      return "{profile} created the discussion {discussion}.";
    case ActivityDiscussionSubject.DISCUSSION_REPLIED:
      if (options.isAuthorCurrentActor) {
        return "You replied to the discussion {discussion}.";
      }
      return "{profile} replied to the discussion {discussion}.";
    case ActivityDiscussionSubject.DISCUSSION_RENAMED:
      if (options.isAuthorCurrentActor) {
        return "You renamed the discussion from {old_discussion} to {discussion}.";
      }
      return "{profile} renamed the discussion from {old_discussion} to {discussion}.";
    case ActivityDiscussionSubject.DISCUSSION_ARCHIVED:
      if (options.isAuthorCurrentActor) {
        return "You archived the discussion {discussion}.";
      }
      return "{profile} archived the discussion {discussion}.";
    case ActivityDiscussionSubject.DISCUSSION_DELETED:
      if (options.isAuthorCurrentActor) {
        return "You deleted the discussion {discussion}.";
      }
      return "{profile} deleted the discussion {discussion}.";
    default:
      return undefined;
  }
}
