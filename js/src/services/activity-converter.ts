import { IActivity, IPatchedActivity } from "@/types/activity.model";
import { IGroup } from "@/types/actor";
import { IMember } from "@/types/actor/member.model";
import { IDiscussion } from "@/types/discussions";
import { ActivityType } from "@/types/enums";
import { IEvent } from "@/types/event.model";
import { IPost } from "@/types/post.model";
import { IResource } from "@/types/resource";
import { convertDiscussionActivity } from "./activity/discussion";
import { convertEventActivity } from "./activity/event";
import { convertGroupActivity } from "./activity/group";
import { convertMemberActivity } from "./activity/member";
import { convertPostActivity } from "./activity/post";
import { convertResourceActivity } from "./activity/resource";
import { convertActivityOptions, reduceSubjectParams } from "./activity/utils";

export function convertActivity(
  activity: IActivity,
  options: convertActivityOptions = {}
): string | undefined {
  const converter = mapActivityTypeToFunction(activity.type);
  const patchedActivity = {
    ...activity,
    subjectParams: reduceSubjectParams(activity),
  };
  return converter(patchedActivity, options);
}

type activityConverter<T> = (
  activity: IPatchedActivity<T>,
  options: any
) => string | undefined;

const mapActivityTypeToFunction = (
  activityType: string
): activityConverter<any> => {
  switch (activityType) {
    case ActivityType.EVENT:
      return convertEventActivity as activityConverter<IEvent>;
    case ActivityType.POST:
      return convertPostActivity as activityConverter<IPost>;
    case ActivityType.MEMBER:
      return convertMemberActivity as activityConverter<IMember>;
    case ActivityType.RESOURCE:
      return convertResourceActivity as activityConverter<IResource>;
    case ActivityType.DISCUSSION:
      return convertDiscussionActivity as activityConverter<IDiscussion>;
    case ActivityType.GROUP:
      return convertGroupActivity as activityConverter<IGroup>;
  }
  return () => undefined;
};
