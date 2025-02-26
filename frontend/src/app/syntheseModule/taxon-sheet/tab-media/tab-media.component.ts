import { Component, HostListener, OnInit } from '@angular/core';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { MediaService } from '@geonature_common/service/media.service';
import { TaxonSheetService } from '../taxon-sheet.service';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';
import { PageEvent } from '@angular/material/paginator';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';

export interface Pagination {
  totalItems: number;
  currentPage: number;
  perPage: number;
}

enum Direction {
  BACKWARD,
  FORWARD,
}

export const DEFAULT_PAGINATION: Pagination = {
  totalItems: 0,
  currentPage: 0,
  perPage: 10,
};

@Component({
  standalone: true,
  selector: 'pnx-tab-media',
  templateUrl: './tab-media.component.html',
  styleUrls: ['./tab-media.component.scss'],
  imports: [GN2CommonModule, CommonModule],
})
export class TabMediaComponent implements OnInit {
  public medias: any[] = [];
  public selectedMedia: any = {};
  taxon: Taxon | null = null;
  pagination: Pagination = DEFAULT_PAGINATION;

  constructor(
    public ms: MediaService,
    private _tss: TaxonSheetService,
    private _syntheseDataService: SyntheseDataService
  ) {}

  ngOnInit() {
    this._tss.taxon.subscribe((taxon) => {
      this.taxon = taxon;
      if (!this.taxon) {
        this.medias = [];
        this.selectedMedia = {};
        this.pagination = DEFAULT_PAGINATION;
        return;
      }
      this.loadMedias();
    });
  }

  loadMedias(selectedMediaIndex: number = 0) {
    this._syntheseDataService
      .getTaxonMedias(this.taxon.cd_ref, {
        page: this.pagination.currentPage + 1,
        per_page: this.pagination.perPage,
      })
      .subscribe((response) => {
        this.medias = response.items;
        this.pagination = {
          totalItems: response.total,
          currentPage: response.page - 1,
          perPage: response.per_page,
        };
        if (!this.medias.some((media) => media.id_media == this.selectedMedia.id_media)) {
          this.selectedMedia = this.medias[selectedMediaIndex];
        }
      });
  }

  selectMedia(media: any) {
    this.selectedMedia = media;
  }

  onPageChange(event: PageEvent) {
    this.pagination.currentPage = event.pageIndex;
    this.pagination.perPage = event.pageSize;
    this.loadMedias();
  }

  @HostListener('window:keydown', ['$event'])
  onKeydown(event: KeyboardEvent) {
    if (event.key === 'ArrowLeft') {
      event.preventDefault();
      this.selectFollowingMedia(Direction.BACKWARD);
    } else if (event.key === 'ArrowRight') {
      event.preventDefault();
      this.selectFollowingMedia(Direction.FORWARD);
    }
  }

  selectFollowingMedia(direction: Direction) {
    const mediaIndex = this.medias.findIndex(
      (item) => this.selectedMedia.id_media === item.id_media
    );
    const nextIndex = direction == Direction.FORWARD ? mediaIndex + 1 : mediaIndex - 1;

    // Forward
    if (nextIndex > this.medias.length - 1) {
      // Check if not last page
      if (
        this.pagination.perPage * (this.pagination.currentPage + 1) <
        this.pagination.totalItems
      ) {
        this.pagination.currentPage++;
        this.loadMedias();
        return;
      } else {
        return;
      }
    }

    // Backward
    if (nextIndex < 0) {
      // Check if not first
      if (this.pagination.currentPage > 0) {
        this.pagination.currentPage--;
        this.loadMedias(this.pagination.perPage - 1);
        return;
      } else {
        return;
      }
    }

    // Same page
    this.selectMedia(this.medias[nextIndex]);
  }
}
