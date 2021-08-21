import { EventSortField, SortDirection } from "./enums";

export interface ISorting {
  title: string;
  orderBy: EventSortField;
  direction: SortDirection;
}

export class SortingUpcoming implements ISorting {
  title = "Upcoming Events";
  orderBy = EventSortField.BEGINS_ON;
  direction = SortDirection.ASC;
}

export class SortingCreated implements ISorting {
  title = "Recently created Events";
  orderBy = EventSortField.INSERTED_AT;
  direction = SortDirection.DESC;
}
