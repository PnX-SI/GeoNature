import { Component, OnInit } from '@angular/core';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';
import { ConfigService } from '@geonature/services/config.service';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { TaxonSheetService } from '../taxon-sheet.service';
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
@Component({
  standalone: true,
  selector: 'tab-observers',
  templateUrl: 'tab-observers.component.html',
  styleUrls: ['tab-observers.component.scss'],
  imports: [GN2CommonModule, CommonModule],
})
export class TabObserversComponent implements OnInit {
  readonly COLUMNS = [
    { prop: 'observer', name: 'Observateur', sort: true, order: 'asc' },
    { prop: 'date_min', name: 'Plus ancienne' },
    { prop: 'date_max', name: 'Plus récente' },
    { prop: 'observation_count', name: "Nombre d'observations" },
    { prop: 'media_count', name: 'Nombre de media' },
  ];
  readonly DEFAULT_SORT = {
    ...DEFAULT_SORT,
    sortBy: this.COLUMNS[0].prop,
    sortOrder: SORT_ORDER.ASC,
  };
  items: any[] = [];
  pagination: SyntheseDataPaginationItem = DEFAULT_PAGINATION;
  sort: SyntheseDataSortItem = this.DEFAULT_SORT;

  constructor(
    private _syntheseDataService: SyntheseDataService,
    private _config: ConfigService,
    private _tss: TaxonSheetService
  ) {}

  ngOnInit() {
    this._tss.taxon.subscribe((taxon: Taxon | null) => {
      this.fetchObservers();
    });
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

  fetchObservers() {
    const taxon = this._tss.taxon.getValue();
    if (!taxon) {
      this.items = [];
      this.pagination = DEFAULT_PAGINATION;
      this.sort = this.DEFAULT_SORT;
      return;
    }
    this._syntheseDataService
      .getSyntheseTaxonSheetObservers(taxon.cd_ref, this.pagination, this.sort)
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
}
