import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { ConfigService } from '@geonature/services/config.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { CommonService } from '@geonature_common/service/common.service';

@Component({
  selector: 'pnx-taxon-sheet',
  templateUrl: 'taxon-sheet.component.html',
  styleUrls: ['taxon-sheet.component.scss'],
})
export class TaxonSheetComponent implements OnInit {
  public taxon: any;
  public profile: any;
  public profilArea: any;
  public mediaUrl: any;
  constructor(
    private _route: ActivatedRoute,
    private _ds: DataFormService,
    private _commonService: CommonService,
    public cs: ConfigService
  ) {}

  ngOnInit() {
    this._route.params.subscribe((params) => {
      const cdNom = params['cd_nom'];
      if (cdNom) {
        this._ds.getTaxonInfo(cdNom).subscribe((taxon) => {
          this.taxon = taxon;
          this._ds.getProfile(taxon.cd_ref).subscribe(
            (profil) => {
              this.profile = profil.properties;
              this.profilArea = profil;
              this._ds.getTaxonAttributsAndMedia(taxon.cd_ref).subscribe((taxonAttrAndMedias) => {
                const media = taxonAttrAndMedias.medias.find(
                  (m) => m.id_type == this.cs['TAXHUB']['ID_TYPE_MAIN_PHOTO']
                );
                if (media) {
                  this.mediaUrl = `${this.cs.API_TAXHUB}/tmedias/thumbnail/${media.id_media}?h=300&w300`;
                }
              });
            },
            (errors) => {
              console.log(errors);
              if (errors.status == 404) {
                this._commonService.regularToaster('warning', 'Aucune donnée pour ce taxon');
              }
            }
          );
        });
      }
    });
  }
}
