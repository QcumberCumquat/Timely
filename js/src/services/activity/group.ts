import { IPatchedActivity } from "@/types/activity.model";
import { IGroup } from "@/types/actor";
import { ActivityGroupSubject } from "@/types/enums";
import { convertActivityOptions } from "./utils";

export function convertGroupActivity(
  activity: IPatchedActivity<IGroup>,
  options: convertActivityOptions
): string | undefined {
  switch (activity.subject) {
    case ActivityGroupSubject.GROUP_CREATED:
      if (options.isAuthorCurrentActor) {
        return "You created the group {group}.";
      }
      return "{profile} created the group {group}.";
    case ActivityGroupSubject.GROUP_UPDATED:
      if (options.isAuthorCurrentActor) {
        return "You updated the group {group}.";
      }
      return "{profile} updated the group {group}.";
    default:
      return undefined;
  }
}
