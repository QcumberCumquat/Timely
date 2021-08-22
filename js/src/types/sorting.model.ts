import { EventSortField, SortDirection } from "./enums";

export const SORTING_UPCOMING = {
  title: "Upcoming Events",
  orderBy: EventSortField.BEGINS_ON,
  direction: SortDirection.ASC,
};

export const SORTING_CREATED = {
  title: "Recently created Events",
  orderBy: EventSortField.INSERTED_AT,
  direction: SortDirection.DESC,
};
