import { Injectable } from '@angular/core';
import { SyntheseDataPaginationItem } from '@geonature_common/form/synthese-form/synthese-data-pagination-item';
import { SORT_ORDER, SyntheseDataSortItem } from '@geonature_common/form/synthese-form/synthese-data-sort-item';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { sortBy } from '@librairies/cypress/types/lodash';

@Injectable()
export class SyntheseApiProxyService {
  constructor(private _dataService: SyntheseDataService) {}

  // //////////////////////////////////////////////////////////////////////////
  // Pagination and Sort
  // //////////////////////////////////////////////////////////////////////////

  readonly DEFAULT_PAGINATION: SyntheseDataPaginationItem = {
    totalItems: 0,
    currentPage: 1,
    perPage: 15,
  };
  readonly DEFAULT_SORTING: SyntheseDataSortItem = {
    sortOrder: SORT_ORDER.DESC,
    sortBy: 'date_min',
  };

  pagination: SyntheseDataPaginationItem;
  sort?: SyntheseDataSortItem;

  // //////////////////////////////////////////////////////////////////////////
  // Filters
  // //////////////////////////////////////////////////////////////////////////
  _filters: {};

  get filters() {
    return this.filters;
  }
  set filters(filters: any) {
    // reset pagination and sort
    this.pagination.currentPage = 1;
    this.sort.sortBy = this.DEFAULT_SORTING.sortBy;
    this.sort.sortOrder = this.DEFAULT_SORTING.sortOrder;

    this.filters = filters;
    console.log(this.filters);
  }

  observationsPaginated: [];

  public fetchObservations() {

  }
}
