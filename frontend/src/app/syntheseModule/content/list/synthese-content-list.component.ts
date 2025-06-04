import {
  Component,
} from '@angular/core';
import { SyntheseContentListColumnsService } from './synthese-content-list-columns.service';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';
import { SyntheseDataPaginationItem } from '@geonature_common/form/synthese-form/synthese-data-pagination-item';
import { SORT_ORDER, SyntheseDataSortItem } from '@geonature_common/form/synthese-form/synthese-data-sort-item';
import { Subject } from 'rxjs';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';

@Component({
  standalone: true,
  selector: 'pnx-synthese-content-list',
  templateUrl: 'synthese-content-list.component.html',
  styleUrls: ['synthese-content-list.component.scss'],
  imports: [GN2CommonModule, CommonModule],
  providers: [SyntheseContentListColumnsService],
})
export class SyntheseContentListComponent {
  constructor(
    public columnService: SyntheseContentListColumnsService,
    private _dataService: SyntheseDataService
  ) {
  }

  // //////////////////////////////////////////////////////////////////////////
  // Pagination and sorting
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

  pagination: SyntheseDataPaginationItem = this.DEFAULT_PAGINATION;
  sort: SyntheseDataSortItem = this.DEFAULT_SORTING;

  onChangePage(event: any) {
    this.pagination.currentPage = event.offset + 1;
    this._fetchObservations();
  }

  onColumnSort(event: any) {
    this.sort = {
      sortBy: event.newValue,
      sortOrder: event.column.prop,
    };
    this.pagination.currentPage = 1;
    this._fetchObservations();
  }

  // //////////////////////////////////////////////////////////////////////////
  // Obnservations
  // //////////////////////////////////////////////////////////////////////////
  private destroy$ = new Subject<void>();
  observations = [];

  private _fetchObservations() {
    this._dataService.fetchObservationsList(this.pagination, this.sort);
  }

  private _transformObservations(items: any[]): any[] {
    return items.map((item) => ({
      ...item,
      observation: item.synthese,
    }));
  }

  private _setObservations(data: any) {
    this.observations = this._transformObservations(data.items);
    this.pagination = {
      totalItems: data.total,
      currentPage: data.page,
      perPage: data.per_page,
    };
  }

  // //////////////////////////////////////////////////////////////////////////
  // data
  // //////////////////////////////////////////////////////////////////////////

  data: Array<any>;
}
