import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { ConfigService } from '@geonature/services/config.service';
import { TaxonSheetService } from '../taxon-sheet.service';

@Component({
  standalone: true,
  selector: 'infos',
  templateUrl: 'infos.component.html',
  styleUrls: ['infos.component.scss'],
  imports: [CommonModule],
})
export class InfosComponent implements OnInit {
  mediaUrl: string;
  taxon: Taxon | null = null;

  constructor(
    private _config: ConfigService,
    private _ds: DataFormService,
    private _tss: TaxonSheetService
  ) {}

  ngOnInit() {
    this._tss.taxon.subscribe((taxon: Taxon | null) => {
      this.taxon = taxon;
      if (!this.taxon) {
        return;
      }
      this._ds
        .getTaxonInfo(this.taxon.cd_ref, ['medias', 'cd_nom'])
        .subscribe((taxonAttrAndMedias) => {
          const media = taxonAttrAndMedias['medias'].find(
            (m) => m.id_type == this._config.TAXHUB.ID_TYPE_MAIN_PHOTO
          );
          if (media) {
            this.mediaUrl = `${this._config.API_TAXHUB}/tmedias/thumbnail/${media.id_media}?h=300&w300`;
          }
        });
    });
  }
}
