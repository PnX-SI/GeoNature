import { Injectable } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';
import { SyntheseDataPaginationItem } from '@geonature_common/form/synthese-form/synthese-data-pagination-item';
import {
  SORT_ORDER,
  SyntheseDataSortItem,
} from '@geonature_common/form/synthese-form/synthese-data-sort-item';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { BehaviorSubject } from '@librairies/rxjs';

@Injectable()
export class SyntheseApiProxyService {
  constructor(
    public dataService: SyntheseDataService,
    public config: ConfigService
  ) {}

  // //////////////////////////////////////////////////////////////////////////
  // Pagination and Sort
  // //////////////////////////////////////////////////////////////////////////

  readonly DEFAULT_PAGINATION: SyntheseDataPaginationItem = {
    totalItems: 0,
    currentPage: 1,
    perPage: 25,
  };
  readonly DEFAULT_SORTING: SyntheseDataSortItem = {
    sortOrder: SORT_ORDER.DESC,
    sortBy: 'date_min',
  };

  pagination: SyntheseDataPaginationItem = this.DEFAULT_PAGINATION;
  sort: SyntheseDataSortItem = this.DEFAULT_SORTING;

  // //////////////////////////////////////////////////////////////////////////
  // Filters
  // //////////////////////////////////////////////////////////////////////////
  _filters: {};

  get filters() {
    return this._filters;
  }
  set filters(filters: any) {
    // reset pagination and sort
    this.pagination.currentPage = 1;
    this.sort.sortBy = this.DEFAULT_SORTING.sortBy;
    this.sort.sortOrder = this.DEFAULT_SORTING.sortOrder;

    this._filters = filters;
  }

  // //////////////////////////////////////////////////////////////////////////
  // observationsList
  // //////////////////////////////////////////////////////////////////////////

  observationsList: [];

  // //////////////////////////////////////////////////////////////////////////
  // geomList
  // //////////////////////////////////////////////////////////////////////////

  public geomList: BehaviorSubject<any> = new BehaviorSubject([]);

  // //////////////////////////////////////////////////////////////////////////
  // Filters
  // //////////////////////////////////////////////////////////////////////////

  private _concatFilterPaginationAndSort() {
    return {
      ...this._filters,
      per_page: this.pagination.perPage,
      page: this.pagination.currentPage,
      with_geom: false,
    };
  }

  public fetchObservationsList() {
    this.dataService
      .getObservations(this._concatFilterPaginationAndSort())
      .subscribe((observations) => {
        this.observationsList = observations.items;
        this.pagination.totalItems = observations.total;
        this.pagination.perPage = observations.per_page;
        this.pagination.currentPage = observations.page;
      });
  }

  private _concatMapFilter(boundingBox) {
    const result = { ...this.filters };
    if (!result['geoIntersection'] && boundingBox !== null) result['geoIntersection'] = boundingBox;
    return result;
  }

  public fetchMapAreas(boundingBox = null) {
    this.dataService
      .getAreas(
        this._concatMapFilter(boundingBox),
        this.config['SYNTHESE']['AREA_AGGREGATION_TYPE']
      )
      .subscribe((response) => {
        this.geomList.next(response['features']);
      });
  }
}
