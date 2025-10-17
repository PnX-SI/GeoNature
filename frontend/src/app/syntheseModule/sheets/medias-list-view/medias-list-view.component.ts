import { Component, EventEmitter, HostListener, Input, OnInit, Output } from '@angular/core';
import { MediaService } from '@geonature_common/service/media.service';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';
import { PageEvent } from '@angular/material/paginator';
import {
  DEFAULT_PAGINATION,
  SyntheseDataPaginationItem,
} from '@geonature_common/form/synthese-form/synthese-data-pagination-item';
import { Loadable } from '@geonature/syntheseModule/sheets/loadable';

enum Direction {
  BACKWARD,
  FORWARD,
}

@Component({
  standalone: true,
  selector: 'medias-list-view',
  templateUrl: './medias-list-view.component.html',
  styleUrls: ['./medias-list-view.component.scss'],
  imports: [GN2CommonModule, CommonModule],
})
export class MediasListViewComponent {
  medias: any[] = [];
  pagination: SyntheseDataPaginationItem = DEFAULT_PAGINATION;
  selectedMedia: any = {};
  mediaIndexToSelectOnUpdate: number = 0;

  constructor(public ms: MediaService) {}

  @Input()
  set mediaCollection(value: { items: any[]; pagination: SyntheseDataPaginationItem }) {
    this.medias = value.items;
    this.pagination = value.pagination;
    if (
      this.medias.length &&
      !this.medias.some((media) => media.id_media == this.selectedMedia.id_media)
    ) {
      this.selectedMedia = this.medias[this.mediaIndexToSelectOnUpdate];
    }
  }

  @Output()
  refreshMedias = new EventEmitter<SyntheseDataPaginationItem>();

  selectMedia(media: any) {
    this.selectedMedia = media;
  }

  onPageChange(event: PageEvent) {
    this.mediaIndexToSelectOnUpdate = 0;
    this.pagination.currentPage = event.pageIndex + 1;
    this.pagination.perPage = event.pageSize;
    this.refreshMedias.emit(this.pagination);
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
      if (this.pagination.perPage * this.pagination.currentPage < this.pagination.totalItems) {
        this.mediaIndexToSelectOnUpdate = 0;
        this.pagination.currentPage++;
        this.refreshMedias.emit(this.pagination);
        return;
      } else {
        return;
      }
    }

    // Backward
    if (nextIndex < 0) {
      // Check if not first
      if (this.pagination.currentPage > 1) {
        this.pagination.currentPage--;
        this.mediaIndexToSelectOnUpdate = this.pagination.perPage - 1;
        this.refreshMedias.emit(this.pagination);
        return;
      } else {
        return;
      }
    }

    // Same page
    this.selectMedia(this.medias[nextIndex]);
  }
}
