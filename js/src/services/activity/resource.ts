import { IPatchedActivity } from "@/types/activity.model";
import { ActivityResourceSubject } from "@/types/enums";
import { IResource } from "@/types/resource";
import { convertActivityOptions } from "./utils";

export function convertResourceActivity(
  activity: IPatchedActivity<IResource>,
  options: convertActivityOptions
): string | undefined {
  switch (activity.subject) {
    case ActivityResourceSubject.RESOURCE_CREATED:
      if (activity?.object?.type === "folder") {
        if (options.isAuthorCurrentActor) {
          return "You created the folder {resource}.";
        }
        return "{profile} created the folder {resource}.";
      }
      if (options.isAuthorCurrentActor) {
        return "You created the resource {resource}.";
      }
      return "{profile} created the resource {resource}.";
    case ActivityResourceSubject.RESOURCE_MOVED:
      if (activity?.object?.type === "folder") {
        if (options.parentDirectory === null) {
          if (options.isAuthorCurrentActor) {
            return "You moved the folder {resource} to the root folder.";
          }
          return "{profile} moved the folder {resource} to the root folder.";
        }
        if (options.isAuthorCurrentActor) {
          return "You moved the folder {resource} into {new_path}.";
        }
        return "{profile} moved the folder {resource} into {new_path}.";
      }
      if (options.parentDirectory === null) {
        if (options.isAuthorCurrentActor) {
          return "You moved the resource {resource} to the root folder.";
        }
        return "{profile} moved the resource {resource} to the root folder.";
      }
      if (options.isAuthorCurrentActor) {
        return "You moved the resource {resource} into {new_path}.";
      }
      return "{profile} moved the resource {resource} into {new_path}.";
    case ActivityResourceSubject.RESOURCE_UPDATED:
      if (activity?.object?.type === "folder") {
        if (options.isAuthorCurrentActor) {
          return "You renamed the folder from {old_resource_title} to {resource}.";
        }
        return "{profile} renamed the folder from {old_resource_title} to {resource}.";
      }
      if (options.isAuthorCurrentActor) {
        return "You renamed the resource from {old_resource_title} to {resource}.";
      }
      return "{profile} renamed the resource from {old_resource_title} to {resource}.";
    case ActivityResourceSubject.RESOURCE_DELETED:
      if (activity?.object?.type === "folder") {
        if (options.isAuthorCurrentActor) {
          return "You deleted the folder {resource}.";
        }
        return "{profile} deleted the folder {resource}.";
      }
      if (options.isAuthorCurrentActor) {
        return "You deleted the resource {resource}.";
      }
      return "{profile} deleted the resource {resource}.";
    default:
      return undefined;
  }
}
