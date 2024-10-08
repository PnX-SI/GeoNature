import { Component, OnInit, Input } from '@angular/core';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { MediaService } from '@geonature_common/service/media.service';
import { finalize } from 'rxjs/operators';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-synthese-modal-info-obs',
  templateUrl: 'modal-info-obs.component.html',
})
export class ModalInfoObsComponent implements OnInit {
  @Input() syntheseObs: any;
  public selectedObs;
  public selectedObsTaxonDetail;
  public formatedAreas = [];
  public SYNTHESE_CONFIG = null;
  public isLoading = false;
  constructor(
    private _gnDataService: DataFormService,
    private _dataService: SyntheseDataService,
    public activeModal: NgbActiveModal,
    public mediaService: MediaService,
    public config: ConfigService
  ) {
    this.SYNTHESE_CONFIG = this.config.SYNTHESE;
  }

  ngOnInit() {
    this.loadOneSyntheseReleve(this.syntheseObs);
  }

  loadOneSyntheseReleve(syntheseObs) {
    this.isLoading = true;
    this._dataService
      .getOneSyntheseObservation(syntheseObs.id)
      .pipe(
        finalize(() => {
          this.isLoading = false;
        })
      )
      .subscribe((data) => {
        this.selectedObs = data;
        this.selectedObs['municipalities'] = [];
        this.selectedObs['other_areas'] = [];
        this.selectedObs['actors'] = this.selectedObs['actors'].split('|');
        const areaDict = {};
        // for each area type we want all the areas: we build an dict of array
        this.selectedObs.areas.forEach((area) => {
          if (!areaDict[area.area_type.type_name]) {
            areaDict[area.area_type.type_name] = [area];
          } else {
            areaDict[area.area_type.type_name].push(area);
          }
        });
        // for angular tempate we need to convert it into a aray
        for (let key in areaDict) {
          this.formatedAreas.push({ area_type: key, areas: areaDict[key] });
        }

        // this.inpnMapUrl = `https://inpn.mnhn.fr/cartosvg/couchegeo/repartition/atlas/${
        //   this.selectedObs['cd_nom']
        //   }/fr_light_l93,fr_light_mer_l93,fr_lit_l93)`;
      });

    const taxhubFields = ['attributs', 'attributs.bib_attribut.label_attribut', 'status'];
    this._gnDataService.getTaxonInfo(syntheseObs.cd_nom, taxhubFields).subscribe((taxInfo) => {
      this.selectedObsTaxonDetail = taxInfo;
      // filter attributs
      this.selectedObsTaxonDetail.attributs = taxInfo['attributs'].filter((v) =>
        this.config.SYNTHESE.ID_ATTRIBUT_TAXHUB.includes(v.id_attribut)
      );
    });
  }

  backToModule(url_source, id_pk_source) {
    window.open(url_source + '/' + id_pk_source, '_blank');
  }
}
