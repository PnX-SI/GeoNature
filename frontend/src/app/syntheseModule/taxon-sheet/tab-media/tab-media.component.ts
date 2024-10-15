import { Component, OnInit } from '@angular/core';

import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { MediaService } from '@geonature_common/service/media.service';
import { TaxonSheetService } from '../taxon-sheet.service';

@Component({
  selector: 'pnx-tab-media',
  templateUrl: './tab-media.component.html',
  styleUrls: ['./tab-media.component.scss'],
  providers: [MediaService],
})
export class TabMediaComponent implements OnInit {
  private _medias: any;
  private _thumbnail: any[] = [];
  taxon: Taxon | null = null;

  constructor(
    private _ms: MediaService,
    private _tss: TaxonSheetService
  ) {}

  ngOnInit() {
    this._tss.taxon.subscribe((taxon) => {
      this.taxon = taxon;
      if (!this.taxon) {
        return;
      }
      this._ms.getMediasSpecies(this.taxon.cd_nom).subscribe((medias) => {
        this._medias = medias.items;
        if (this._medias) {
          for (const media of this._medias) {
            const thumbnail = this._ms.href(media, 300);
            this._thumbnail.push(thumbnail);
          }
          console.log(this._thumbnail);
        }
      });
    });
  }
}
