import { Component, OnInit, Input } from '@angular/core';
import { DataService } from '../../../services/data.service';
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
  public SYNTHESE_CONFIG = AppConfig.SYNTHESE;
  constructor(
    private _gnDataService: DataFormService,
    private _dataService: DataService,
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
      this.selectedObs.areas.forEach(area => {
        if (area.id_type === AppConfig.BDD.id_area_type_municipality) {
          this.selectedObs['municipalities'].push(area);
        } else {
          this.selectedObs['other_areas'].push(area);
        }
      });
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
