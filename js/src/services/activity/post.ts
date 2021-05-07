import { IPatchedActivity } from "@/types/activity.model";
import { ActivityPostSubject } from "@/types/enums";
import { IPost } from "@/types/post.model";
import { convertActivityOptions } from "./utils";

export function convertPostActivity(
  activity: IPatchedActivity<IPost>,
  options: convertActivityOptions
): string | undefined {
  switch (activity.subject) {
    case ActivityPostSubject.POST_CREATED:
      if (options.isAuthorCurrentActor) {
        return "You created the post {post}.";
      }
      return "The post {post} was created by {profile}.";
    case ActivityPostSubject.POST_UPDATED:
      if (options.isAuthorCurrentActor) {
        return "You updated the post {post}.";
      }
      return "The post {post} was updated by {profile}.";
    case ActivityPostSubject.POST_DELETED:
      if (options.isAuthorCurrentActor) {
        return "You deleted the post {post}.";
      }
      return "The post {post} was deleted by {profile}.";
    default:
      return undefined;
  }
}
