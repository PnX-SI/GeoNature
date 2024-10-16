import { Component, OnInit } from '@angular/core';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { MediaService } from '@geonature_common/service/media.service';
import { TaxonSheetService } from '../taxon-sheet.service';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';
import { PageEvent } from '@angular/material/paginator';

@Component({
  standalone: true,
  selector: 'pnx-tab-media',
  templateUrl: './tab-media.component.html',
  styleUrls: ['./tab-media.component.scss'],
  providers: [MediaService],
  imports: [GN2CommonModule, CommonModule],
})
export class TabMediaComponent implements OnInit {
  public medias: any[] = [];
  public thumbnail: any[] = [];
  public selectedMedia: any = {};
  taxon: Taxon | null = null;
  pageSize: number = 12;
  totalRows: number = 0;
  currentPage: number = 1;

  constructor(
    protected _ms: MediaService,
    private _tss: TaxonSheetService
  ) {}

  ngOnInit() {
    this._tss.taxon.subscribe((taxon) => {
      this.taxon = taxon;
      if (!this.taxon) {
        return;
      }
      this.loadMedias();
    });
  }

  loadMedias(page: number = 1, pageSize: number = this.pageSize) {
    const params = {
      page: page,
      per_page: pageSize,
    };

    this._ms.getMediasSpecies(this.taxon!.cd_nom, params).subscribe((response) => {
      this.medias = response.items;
      this.totalRows = response.total;
      this.thumbnail = [];

      for (const media of this.medias) {
        const thumbnail = this._ms.href(media, 300);
        this.thumbnail.push(thumbnail);
      }

      if (Object.keys(this.selectedMedia).length === 0) {
        this.selectedMedia = this.medias[0];
      }
    });
  }

  selectMedia(media: any) {
    this.selectedMedia = media;
  }

  onPageChange(event: PageEvent) {
    this.currentPage = event.pageIndex + 1;
    this.pageSize = event.pageSize;
    this.loadMedias(this.currentPage, this.pageSize);
  }
}
