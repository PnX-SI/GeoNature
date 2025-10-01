import { Component, OnInit } from '@angular/core';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { TaxonSheetService } from '../taxon-sheet.service';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import {
  DEFAULT_PAGINATION,
  SyntheseDataPaginationItem,
} from '@geonature_common/form/synthese-form/synthese-data-pagination-item';
import { MediasComponent } from '@geonature/syntheseModule/sheets/medias/medias.component';
import { Loadable } from '@geonature/syntheseModule/sheets/loadable';
import { finalize } from 'rxjs/operators';

@Component({
  standalone: true,
  templateUrl: './tab-media.component.html',
  imports: [GN2CommonModule, CommonModule, MediasComponent],
})
export class TabMediaComponent extends Loadable implements OnInit {
  public medias: {
    items: any[];
    pagination: SyntheseDataPaginationItem;
  } = {
    items: [],
    pagination: DEFAULT_PAGINATION,
  };
  taxon: Taxon | null = null;

  constructor(
    private _tss: TaxonSheetService,
    private _syntheseDataService: SyntheseDataService
  ) {
    super();
  }

  ngOnInit() {
    this._tss.taxon.subscribe((taxon) => {
      this.taxon = taxon;
      if (!this.taxon) {
        this.medias = {
          items: [],
          pagination: DEFAULT_PAGINATION,
        };
        return;
      }
      this.loadMedias(this.medias.pagination);
    });
  }

  loadMedias(pagination: SyntheseDataPaginationItem) {
    this.startLoading();

    this._syntheseDataService
      .getTaxonMedias(this.taxon.cd_ref, {
        page: pagination.currentPage,
        per_page: pagination.perPage,
      })
      .pipe(finalize(() => this.stopLoading()))
      .subscribe((response) => {
        this.medias = {
          items: response.items,
          pagination: {
            totalItems: response.total,
            currentPage: response.page,
            perPage: response.per_page,
          },
        };
      });
  }
}
