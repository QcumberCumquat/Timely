import { IActivity } from "@/types/activity.model";

export function reduceSubjectParams(
  activity: IActivity
): Record<string, string> {
  return activity.subjectParams.reduce(
    (acc: Record<string, string>, { key, value }) => {
      acc[key] = value;
      return acc;
    },
    {}
  );
}

export type convertActivityOptions = {
  isAuthorCurrentActor?: boolean;
  isObjectMemberCurrentActor?: boolean;
  parentDirectory?: string | undefined | null;
};
