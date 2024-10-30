export enum SORT_ORDER {
  ASC = 'asc',
  DESC = 'desc',
}

export interface SyntheseDataSortItem {
  sortBy: string;
  sortOrder: string;
}

export const DEFAULT_SORT: SyntheseDataSortItem = {
  sortBy: '',
  sortOrder: SORT_ORDER.ASC,
};
