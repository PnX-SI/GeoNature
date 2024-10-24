export interface SyntheseDataPaginationItem {
  totalItems: number;
  currentPage: number;
  perPage: number;
}

export const DEFAULT_PAGINATION: SyntheseDataPaginationItem = {
  totalItems: 0,
  currentPage: 1,
  perPage: 10,
};
