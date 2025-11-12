import { Component, OnInit } from '@angular/core';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { ObserverSheetService } from '../observer-sheet.service';
import { MediasListViewComponent } from '@geonature/syntheseModule/sheets/medias-list-view/medias-list-view.component';
import {
  DEFAULT_PAGINATION,
  SyntheseDataPaginationItem,
} from '@geonature_common/form/synthese-form/synthese-data-pagination-item';
import { Loadable } from '@geonature/syntheseModule/sheets/loadable';
import { finalize } from 'rxjs/operators';

@Component({
  standalone: true,
  templateUrl: './tab-media.component.html',
  imports: [GN2CommonModule, CommonModule, MediasListViewComponent],
})
export class TabMediaComponent extends Loadable implements OnInit {
  public medias: {
    items: any[];
    pagination: SyntheseDataPaginationItem;
  } = {
    items: [],
    pagination: DEFAULT_PAGINATION,
  };
  observer: string | null = null;

  constructor(
    private _oss: ObserverSheetService,
    private _syntheseDataService: SyntheseDataService
  ) {
    super();
  }

  ngOnInit() {
    this._oss.observer.subscribe((observer) => {
      this.observer = observer;
      if (!this.observer) {
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
      .getObserverMedias(this.observer, {
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
