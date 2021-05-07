import { IActor, IGroup } from "./actor";
import { IMember } from "./actor/member.model";
import {
  ActivityDiscussionSubject,
  ActivityEventCommentSubject,
  ActivityEventSubject,
  ActivityGroupSubject,
  ActivityMemberSubject,
  ActivityPostSubject,
  ActivityResourceSubject,
  ActivityType,
} from "./enums";
import { IEvent } from "./event.model";
import { IPost } from "./post.model";
import { IResource } from "./resource";

export type ActivitySubject =
  | ActivityEventSubject
  | ActivityPostSubject
  | ActivityMemberSubject
  | ActivityResourceSubject
  | ActivityDiscussionSubject
  | ActivityGroupSubject
  | ActivityEventCommentSubject;

export type IActivityObject = IEvent | IPost | IGroup | IMember | IResource;
export interface IActivity {
  id: string;
  type: ActivityType;
  subject: ActivitySubject;
  subjectParams: { key: string; value: string }[];
  author: IActor;
  group: IGroup;
  object: IActivityObject;
  insertedAt: string;
}

export interface IPatchedActivity<T>
  extends Omit<IActivity, "subjectParams" | "object"> {
  subjectParams: Record<string, string>;
  object: T;
}
