import {
  Component,
} from '@angular/core';
import { SyntheseContentListColumnsService } from './synthese-content-list-columns.service';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';
import { SyntheseApiProxyService } from '@geonature/syntheseModule/services/synthese-api-proxy.service';
import { SyntheseDataPaginationItem } from '@geonature_common/form/synthese-form/synthese-data-pagination-item';
import { SyntheseDataSortItem } from '@geonature_common/form/synthese-form/synthese-data-sort-item';

@Component({
  standalone: true,
  selector: 'pnx-synthese-content-list',
  templateUrl: 'synthese-content-list.component.html',
  styleUrls: ['synthese-content-list.component.scss'],
  imports: [GN2CommonModule, CommonModule],
  providers: [SyntheseContentListColumnsService],
})
export class SyntheseContentListComponent {
  // //////////////////////////////////////////////////////////////////////////
  // data
  // //////////////////////////////////////////////////////////////////////////

  data: Array<any>;

  constructor(
    public columnService: SyntheseContentListColumnsService,
    private _apiProxyService: SyntheseApiProxyService
  ) {}

  get pagination(): SyntheseDataPaginationItem {
    return this._apiProxyService.pagination;
  }

  get sort(): SyntheseDataSortItem {
    return this._apiProxyService.sort;
  }

  fetchObservations = this._apiProxyService.fetchObservations;

  // //////////////////////////////////////////////////////////////////////////
  // Pagination and sorting
  // //////////////////////////////////////////////////////////////////////////

  onChangePage(event: any) {
    this.pagination.currentPage = event.offset + 1;
    this.fetchObservations();
  }

  onColumnSort(event: any) {
    this.sort.sortBy = event.newValue;
    this.sort.sortOrder = event.column.prop;
    this.pagination.currentPage = 1;
    this.fetchObservations();
  }
}
