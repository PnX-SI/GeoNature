import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { AppConfig } from '@geonature_config/app.config';


@Component({
    selector: 'pnx-taxon-sheet',
    templateUrl: 'taxon-sheet.component.html',
    styleUrls: ['taxon-sheet.component.scss']
})

export class TaxonSheetComponent implements OnInit {
    public taxon: any;
    public profile: any;
    public profilArea: any;
    public mediaUrl: any;
    constructor(private _route: ActivatedRoute, private _ds: DataFormService) { }

    ngOnInit() {
        this._route.params.subscribe(params => {
            const cdNom = params["cd_nom"];
            if(cdNom) {
                this._ds.getTaxonInfo(cdNom).subscribe(taxon => {
                    this.taxon = taxon;
                    this._ds.getProfile(taxon.cd_ref).subscribe(profil => {
                        this.profile = profil.properties;
                        this.profilArea = profil;
                        console.log(profil);
                        this._ds.getTaxonAttributsAndMedia(taxon.cd_ref).subscribe(
                            taxonAttrAndMedias => {
                                const media = taxonAttrAndMedias.medias.find(m => m.id_type == AppConfig.TAXHUB.ID_TYPE_MAIN_PHOTO);
                                if(media) {
                                    this.mediaUrl = `${AppConfig.API_TAXHUB}tmedias/thumbnail/${media.id_media}?h=300&w300`;
                                }
                                // background-image: url(https://taxhub.ecrins-parcnational.fr/api/tmedias/thumbnail/2013?h=150&w=400)

                            }
                        )

                    })
                });
            }
        })
     }

}