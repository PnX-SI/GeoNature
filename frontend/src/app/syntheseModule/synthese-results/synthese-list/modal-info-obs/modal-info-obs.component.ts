import { Component, OnInit, Input } from '@angular/core';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { AppConfig } from '@geonature_config/app.config';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';

@Component({
  selector: 'pnx-synthese-modal-info-obs',
  templateUrl: 'modal-info-obs.component.html'
})
export class ModalInfoObsComponent implements OnInit {
  @Input() oneObsSynthese: any;
  public selectObsTaxonInfo;
  public selectedObs;
  public selectedObsTaxonDetail;
  public formatedAreas = [];
  public SYNTHESE_CONFIG = AppConfig.SYNTHESE;
  constructor(
    private _gnDataService: DataFormService,
    private _dataService: SyntheseDataService,
    public activeModal: NgbActiveModal
  ) {}

  ngOnInit() {
    this.loadOneSyntheseReleve(this.oneObsSynthese);
  }

  loadOneSyntheseReleve(oneObsSynthese) {
    this._dataService.getOneSyntheseObservation(oneObsSynthese.id).subscribe(data => {
      this.selectedObs = data;
      this.selectedObs['municipalities'] = [];
      this.selectedObs['other_areas'] = [];
      this.selectedObs['actors'] = this.selectedObs['actors'].split('|');
      const areaDict = {};
      // for each area type we want all the areas: we build an dict of array
      this.selectedObs.areas.forEach(area => {
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
    this._gnDataService
      .getTaxonAttributsAndMedia(oneObsSynthese.cd_nom, this.SYNTHESE_CONFIG.ID_ATTRIBUT_TAXHUB)
      .subscribe(data => {
        this.selectObsTaxonInfo = data;
      });

    this._gnDataService.getTaxonInfo(oneObsSynthese.cd_nom).subscribe(data => {
      this.selectedObsTaxonDetail = data;
    });
  }

  backToModule(url_source, id_pk_source) {
    window.open(url_source + '/' + id_pk_source, '_blank');
  }
}
