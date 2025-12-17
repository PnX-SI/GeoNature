import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { TaxonSheetService } from '../taxon-sheet.service';

@Component({
  standalone: true,
  selector: 'taxon-image',
  templateUrl: 'taxon-image.component.html',
  styleUrls: ['taxon-image.component.scss'],
  imports: [CommonModule],
})
export class TaxonImageComponent {
  mediaUrl: string = '';

  constructor(
    private _ds: DataFormService,
    private _tss: TaxonSheetService,
    private _config: ConfigService
  ) {}

  ngOnInit() {
    this._tss.taxon.subscribe((taxon: Taxon | null) => {
      this.mediaUrl = '';
      if (!taxon) {
        return;
      }
      this._ds.getTaxonInfo(taxon.cd_ref, ['medias', 'cd_nom']).subscribe((taxonAttrAndMedias) => {
        const media = taxonAttrAndMedias['medias'].find(
          (m) => m.id_type == this._config.TAXHUB.ID_TYPE_MAIN_PHOTO
        );
        if (media) {
          this.mediaUrl = `${this._ds.getTaxhubAPI()}/tmedias/thumbnail/${media.id_media}?h=300&w300`;
        }
      });
    });
  }
}
