import { IPatchedActivity } from "@/types/activity.model";
import { IMember } from "@/types/actor/member.model";
import { ActivityMemberSubject, MemberRole } from "@/types/enums";
import { convertActivityOptions } from "./utils";

export function convertMemberActivity(
  activity: IPatchedActivity<IMember>,
  options: convertActivityOptions
): string | undefined {
  switch (activity.subject) {
    case ActivityMemberSubject.MEMBER_REQUEST:
      if (options.isAuthorCurrentActor) {
        return "You requested to join the group.";
      }
      return "{member} requested to join the group.";
    case ActivityMemberSubject.MEMBER_INVITED:
      if (options.isAuthorCurrentActor) {
        return "You invited {member}.";
      }
      return "{member} was invited by {profile}.";
    case ActivityMemberSubject.MEMBER_ADDED:
      if (options.isAuthorCurrentActor) {
        return "You added the member {member}.";
      }
      return "{profile} added the member {member}.";
    case ActivityMemberSubject.MEMBER_JOINED:
      return "{member} joined the group.";
    case ActivityMemberSubject.MEMBER_UPDATED:
      if (
        activity.subjectParams.member_role &&
        activity.subjectParams.old_role
      ) {
        return roleUpdate(activity, options);
      }
      if (options.isAuthorCurrentActor) {
        return "You updated the member {member}.";
      }
      return "{profile} updated the member {member}.";
    case ActivityMemberSubject.MEMBER_REMOVED:
      if (options.isAuthorCurrentActor) {
        return "You excluded member {member}.";
      }
      return "{profile} excluded member {member}.";
    case ActivityMemberSubject.MEMBER_QUIT:
      return "{profile} quit the group.";
    case ActivityMemberSubject.MEMBER_REJECTED_INVITATION:
      return "{member} rejected the invitation to join the group.";
    case ActivityMemberSubject.MEMBER_ACCEPTED_INVITATION:
      if (options.isAuthorCurrentActor) {
        return "You accepted the invitation to join the group.";
      }
      return "{member} accepted the invitation to join the group.";
    default:
      return undefined;
  }
}

const MEMBER_ROLE_VALUE: Record<string, number> = {
  [MemberRole.MEMBER]: 20,
  [MemberRole.MODERATOR]: 50,
  [MemberRole.ADMINISTRATOR]: 90,
  [MemberRole.CREATOR]: 100,
};

function roleUpdate(
  activity: IPatchedActivity<IMember>,
  options: convertActivityOptions
): string | undefined {
  if (
    Object.keys(MEMBER_ROLE_VALUE).includes(
      activity.subjectParams.member_role
    ) &&
    Object.keys(MEMBER_ROLE_VALUE).includes(activity.subjectParams.old_role)
  ) {
    if (
      MEMBER_ROLE_VALUE[activity.subjectParams.member_role] >
      MEMBER_ROLE_VALUE[activity.subjectParams.old_role]
    ) {
      switch (activity.subjectParams.member_role) {
        case MemberRole.MODERATOR:
          if (options.isAuthorCurrentActor) {
            return "You promoted {member} to moderator.";
          }
          if (options.isObjectMemberCurrentActor) {
            return "You were promoted to moderator by {profile}.";
          }
          return "{profile} promoted {member} to moderator.";
        case MemberRole.ADMINISTRATOR:
          if (options.isAuthorCurrentActor) {
            return "You promoted {member} to administrator.";
          }
          if (options.isObjectMemberCurrentActor) {
            return "You were promoted to administrator by {profile}.";
          }
          return "{profile} promoted {member} to administrator.";
        default:
          if (options.isAuthorCurrentActor) {
            return "You promoted the member {member} to an unknown role.";
          }
          if (options.isObjectMemberCurrentActor) {
            return "You were promoted to an unknown role by {profile}.";
          }
          return "{profile} promoted {member} to an unknown role.";
      }
    } else {
      switch (activity.subjectParams.member_role) {
        case MemberRole.MODERATOR:
          if (options.isAuthorCurrentActor) {
            return "You demoted {member} to moderator.";
          }
          if (options.isObjectMemberCurrentActor) {
            return "You were demoted to moderator by {profile}.";
          }
          return "{profile} demoted {member} to moderator.";
        case MemberRole.MEMBER:
          if (options.isAuthorCurrentActor) {
            return "You demoted {member} to simple member.";
          }
          if (options.isObjectMemberCurrentActor) {
            return "You were demoted to simple member by {profile}.";
          }
          return "{profile} demoted {member} to simple member.";
        default:
          if (options.isAuthorCurrentActor) {
            return "You demoted the member {member} to an unknown role.";
          }
          if (options.isObjectMemberCurrentActor) {
            return "You were demoted to an unknown role by {profile}.";
          }
          return "{profile} demoted {member} to an unknown role.";
      }
    }
  } else {
    if (options.isAuthorCurrentActor) {
      return "You updated the member {member}.";
    }
    return "{profile} updated the member {member}";
  }
}
