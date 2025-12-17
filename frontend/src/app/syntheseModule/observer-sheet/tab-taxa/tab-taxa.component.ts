import { Component, OnInit } from '@angular/core';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { FeatureCollection } from 'geojson';
import { ObserverSheetService } from '../observer-sheet.service';
import { ConfigService } from '@geonature/services/config.service';
import { Router, RouterModule } from '@angular/router';
import { Loadable } from '@geonature/syntheseModule/sheets/loadable';
import {
  DEFAULT_SORT,
  SORT_ORDER,
  SyntheseDataSortItem,
} from '@geonature_common/form/synthese-form/synthese-data-sort-item';
import {
  DEFAULT_PAGINATION,
  SyntheseDataPaginationItem,
} from '@geonature_common/form/synthese-form/synthese-data-pagination-item';
import { finalize } from '@librairies/rxjs/operators';
import { getTaxonSheetRoute } from '@geonature/syntheseModule/taxon-sheet/taxon-sheet.route.service';
import { Observer } from '../observer';

@Component({
  standalone: true,
  selector: 'tab-taxa',
  templateUrl: 'tab-taxa.component.html',
  styleUrls: ['tab-taxa.component.scss'],
  imports: [GN2CommonModule, CommonModule, RouterModule],
})
export class TabTaxaComponent extends Loadable implements OnInit {
  readonly PROP_CD_NOM = 'cd_nom';
  readonly PROP_NOM = 'nom';
  readonly PROP_DATE_MIN = 'date_min';
  readonly PROP_DATE_MAX = 'date_max';
  readonly PROP_OBSERVATION_COUNT = 'observation_count';
  readonly PROP_DATASET_COUNT = 'dataset_count';

  readonly DEFAULT_SORT = {
    ...DEFAULT_SORT,
    sortBy: this.PROP_OBSERVATION_COUNT,
    sortOrder: SORT_ORDER.ASC,
  };
  items: any[] = [];
  pagination: SyntheseDataPaginationItem = DEFAULT_PAGINATION;
  sort: SyntheseDataSortItem = this.DEFAULT_SORT;

  observations: FeatureCollection | null = null;
  constructor(
    private _syntheseDataService: SyntheseDataService,
    private _oss: ObserverSheetService,
    public mapListService: MapListService,
    public config: ConfigService
  ) {
    super();
  }

  ngOnInit() {
    this._oss.observer.subscribe((observer: Observer) => {
      if (!observer) {
        this.observations = null;
        return;
      }

      this.fetchObservations();
    });
  }

  renderDate(date: string): string {
    return new Date(date).toLocaleDateString();
  }

  onChangePage(event) {
    this.pagination.currentPage = event.offset + 1;
    this.fetchObservations();
  }

  onSort(event) {
    this.sort = {
      sortBy: event.column.prop,
      sortOrder: event.newValue,
    };
    this.fetchObservations();
  }

  async fetchObservations() {
    this.startLoading();
    const observer = this._oss.observer.getValue();
    this.items = [];
    if (!observer) {
      this.pagination = DEFAULT_PAGINATION;
      this.sort = this.DEFAULT_SORT;
      this.stopLoading();
      return;
    }

    this._syntheseDataService
      .getSyntheseObserverSheetTaxa(observer, this.pagination, this.sort)
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

  hasTaxonSheet(): boolean {
    return this.config['SYNTHESE']?.['ENABLE_TAXON_SHEETS'] ?? false;
  }

  getTaxonSheetUrl(cd_nom: number): [string] {
    return getTaxonSheetRoute(cd_nom);
  }
}
