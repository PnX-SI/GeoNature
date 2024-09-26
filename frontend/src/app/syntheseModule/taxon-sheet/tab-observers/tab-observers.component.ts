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
@Component({
  standalone: true,
  selector: 'tab-observers',
  templateUrl: 'tab-observers.component.html',
  styleUrls: ['tab-observers.component.scss'],
  imports: [GN2CommonModule, CommonModule],
})
export class TabObserversComponent implements OnInit {
  items: any[] = [];
  pagination: SyntheseDataPaginationItem = DEFAULT_PAGINATION;

  readonly columns = [
    { prop: 'observer', name: 'Observateur' },
    { prop: 'date_min', name: 'Plus ancienne' },
    { prop: 'date_max', name: 'Plus récente' },
    { prop: 'count', name: "Nombre d'observations" },
  ];

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

  fetchObservers() {
    const taxon = this._tss.taxon.getValue();
    if (!taxon) {
      console.log('taxon is undefined');
      return;
    }
    this._syntheseDataService
      .getSyntheseSpeciesSheetObservers(taxon.cd_ref, this.pagination)
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
