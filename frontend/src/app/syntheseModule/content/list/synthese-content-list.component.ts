import {
  Component,
} from '@angular/core';
import { SyntheseContentListColumnsService } from './synthese-content-list-columns.service';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';
import { SyntheseApiProxyService } from '@geonature/syntheseModule/services/synthese-api-proxy.service';
import { SyntheseDataPaginationItem } from '@geonature_common/form/synthese-form/synthese-data-pagination-item';
import { SyntheseDataSortItem } from '@geonature_common/form/synthese-form/synthese-data-sort-item';
import { ConfigService } from '@geonature/services/config.service';
import { RouterModule } from '@librairies/@angular/router';

@Component({
  standalone: true,
  selector: 'pnx-synthese-content-list',
  templateUrl: 'synthese-content-list.component.html',
  styleUrls: ['synthese-content-list.component.scss'],
  imports: [GN2CommonModule, CommonModule, RouterModule],
  providers: [SyntheseContentListColumnsService],
})
export class SyntheseContentListComponent {
  constructor(
    public columnService: SyntheseContentListColumnsService,
    private _apiProxyService: SyntheseApiProxyService,
    public config: ConfigService
  ) {}

  // //////////////////////////////////////////////////////////////////////////
  // data
  // //////////////////////////////////////////////////////////////////////////

  get observationsList() {
    return this._apiProxyService.observationsList;
  }

  get pagination(): SyntheseDataPaginationItem {
    return this._apiProxyService.pagination;
  }

  get sort(): SyntheseDataSortItem {
    return this._apiProxyService.sort;
  }

  // //////////////////////////////////////////////////////////////////////////
  // Pagination and sorting
  // //////////////////////////////////////////////////////////////////////////

  onChangePage(event: any) {
    this.pagination.currentPage = event.offset + 1;
    this._apiProxyService.fetchObservationsList();
  }

  onColumnSort(event: any) {
    this.sort.sortBy = event.newValue;
    this.sort.sortOrder = event.column.prop;
    this.pagination.currentPage = 1;
    this._apiProxyService.fetchObservationsList();
  }

  // //////////////////////////////////////////////////////////////////////////
  // Date
  // //////////////////////////////////////////////////////////////////////////

  getDate(date) {
    function pad(s) {
      return s < 10 ? '0' + s : s;
    }
    const d = new Date(date);
    return [pad(d.getDate()), pad(d.getMonth() + 1), d.getFullYear()].join('-');
  }

  // //////////////////////////////////////////////////////////////////////////
  // Back to module
  // //////////////////////////////////////////////////////////////////////////

  backToModule(url_source, id_pk_source) {
    const link = document.createElement('a');
    link.target = '_blank';
    link.href = url_source + '/' + id_pk_source;
    link.setAttribute('visibility', 'hidden');
    document.body.appendChild(link);
    link.click();
    link.remove();
  }
}
