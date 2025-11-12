import { Component, OnInit } from '@angular/core';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';
import { ConfigService } from '@geonature/services/config.service';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { TaxonSheetService } from '../taxon-sheet.service';
import { getObserverSheetRoute } from '../../observer-sheet/observer-sheet.route.service'
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import {
  DEFAULT_PAGINATION,
  SyntheseDataPaginationItem,
} from '@geonature_common/form/synthese-form/synthese-data-pagination-item';
import {
  DEFAULT_SORT,
  SORT_ORDER,
  SyntheseDataSortItem,
} from '@geonature_common/form/synthese-form/synthese-data-sort-item';
import { Loadable } from '../../sheets/loadable';
import { finalize } from 'rxjs/operators';
import { RouterModule } from '@librairies/@angular/router';
@Component({
  standalone: true,
  selector: 'tab-observers',
  templateUrl: 'tab-observers.component.html',
  styleUrls: ['tab-observers.component.scss'],
  imports: [GN2CommonModule, CommonModule, RouterModule],
})
export class TabObserversComponent extends Loadable implements OnInit {
  readonly PROP_OBSERVER = 'observer';
  readonly PROP_DATE_MIN = 'date_min';
  readonly PROP_DATE_MAX = 'date_max';
  readonly PROP_OBSERVATION_COUNT = 'observation_count';
  readonly PROP_MEDIA_COUNT = 'media_count';

  readonly DEFAULT_SORT = {
    ...DEFAULT_SORT,
    sortBy: this.PROP_OBSERVER,
    sortOrder: SORT_ORDER.ASC,
  };
  items: any[] = [];
  pagination: SyntheseDataPaginationItem = DEFAULT_PAGINATION;
  sort: SyntheseDataSortItem = this.DEFAULT_SORT;

  constructor(
    private _syntheseDataService: SyntheseDataService,
    private _tss: TaxonSheetService,
    private _config: ConfigService

  ) {
    super();
  }

  ngOnInit() {
    this._tss.taxon.subscribe((taxon: Taxon | null) => {
      this.fetchObservers();
    });
  }

  renderDate(date: string): string {
    return new Date(date).toLocaleDateString();
  }

  onChangePage(event) {
    this.pagination.currentPage = event.offset + 1;
    this.fetchObservers();
  }

  onSort(event) {
    this.sort = {
      sortBy: event.column.prop,
      sortOrder: event.newValue,
    };
    this.fetchObservers();
  }

  async fetchObservers() {
    this.startLoading();
    const taxon = this._tss.taxon.getValue();
    this.items = [];
    if (!taxon) {
      this.pagination = DEFAULT_PAGINATION;
      this.sort = this.DEFAULT_SORT;
      this.stopLoading();
      return;
    }
    this._syntheseDataService
      .getSyntheseTaxonSheetObservers(taxon.cd_ref, this.pagination, this.sort)
      .pipe(finalize(() => this.stopLoading()))
      .subscribe((data) => {
        // Store result
        this.items = data.items;
        this.pagination = {
          totalItems: data.total,
          currentPage: data.page,
          perPage: data.per_page,
        };
      });
  }

  hasObserverSheet(): boolean {
    return this._config['SYNTHESE']?.['ENABLE_OBSERVER_SHEETS'] ?? false;
  }

  getObserverSheetUrl(observer: string): [string] {
    return getObserverSheetRoute(observer);
  }
}
