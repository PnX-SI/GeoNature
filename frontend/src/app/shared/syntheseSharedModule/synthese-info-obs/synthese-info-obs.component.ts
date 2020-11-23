import { Component, OnInit, Input } from '@angular/core';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { CommonService } from '@geonature_common/service/common.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { AppConfig } from '@geonature_config/app.config';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { MediaService } from '@geonature_common/service/media.service';
import { finalize } from 'rxjs/operators';

@Component({
  selector: 'pnx-synthese-info-obs',
  templateUrl: 'synthese-info-obs.component.html',
  styleUrls: ['./synthese-info-obs.component.scss']
})
export class SyntheseInfoObsComponent implements OnInit {
  @Input() idSynthese: number;
  @Input() uuidSynthese: any;
  @Input() selectedObs: any;
  @Input() header: boolean = false;
  @Input() validationHistory: Array<any>;
  @Input() selectedObsTaxonDetail: any;
  public selectObsTaxonInfo;
  public formatedAreas = [];
  public CONFIG = AppConfig;
  public isLoading = false;
  public email;
  public mailto: String;
  public validationColor = {
    '0': '#FFFFFF',
    '1': '#8BC34A',
    '2': '#CDDC39',
    '3': '#FF9800',
    '4': '#FF5722',
    '5': '#BDBDBD',
    '6': '#FFFFFF'
  };
  constructor(
    private _gnDataService: DataFormService,
    private _dataService: SyntheseDataService,
    public activeModal: NgbActiveModal,
    public mediaService: MediaService,
    private _commonService: CommonService
  ) { }

  ngOnInit() {
    this.loadOneSyntheseReleve(this.idSynthese);
    this.loadValidationHistory(this.uuidSynthese);
  }

  loadOneSyntheseReleve(idSynthese) {
    this.isLoading = true;
    this._dataService
      .getOneSyntheseObservation(idSynthese)
      .pipe(
        finalize(() => {
          this.isLoading = false;
        })
      )
      .subscribe(data => {
        this.selectedObs = data;
        this.selectedObs['municipalities'] = [];
        this.selectedObs['other_areas'] = [];
        this.selectedObs['actors'] = this.selectedObs['actors'].split('|');
        const date_min = new Date(this.selectedObs.date_min);
        this.selectedObs.date_min = date_min.toLocaleDateString('fr-FR');
        const date_max = new Date(this.selectedObs.date_max);
        this.selectedObs.date_max = date_max.toLocaleDateString('fr-FR');
        if (this.selectedObs.cor_observers) {
          this.email = this.selectedObs.cor_observers.map(el => el.email).join();
          this.mailto = String('mailto:' + this.email);
        }
        const areaDict = {};
        // for each area type we want all the areas: we build an dict of array
        if (this.selectedObs.areas) {
          this.selectedObs.areas.forEach(area => {
            if (!areaDict[area.area_type.type_name]) {
              areaDict[area.area_type.type_name] = [area];
            } else {
              areaDict[area.area_type.type_name].push(area);
            }
          });
        }

        // for angular tempate we need to convert it into a aray
        // tslint:disable-next-line:forin
        for (let key in areaDict) {
          this.formatedAreas.push({ area_type: key, areas: areaDict[key] });
        }

        this._gnDataService
          .getTaxonAttributsAndMedia(data.cd_nom, AppConfig.SYNTHESE.ID_ATTRIBUT_TAXHUB)
          .subscribe(taxAttr => {
            this.selectObsTaxonInfo = taxAttr;
          });

        this._gnDataService.getTaxonInfo(data.cd_nom).subscribe(taxInfo => {
          this.selectedObsTaxonDetail = taxInfo;
        });
      });
  }

  loadValidationHistory(uuid) {
    this._gnDataService.getValidationHistory(uuid).subscribe(
      data => {
        this.validationHistory = data;
        // tslint:disable-next-line:forin
        for (let row in this.validationHistory) {
          // format date
          const date = new Date(this.validationHistory[row].date);
          this.validationHistory[row].date = date.toLocaleDateString('fr-FR');
          // format comments
          if (
            this.validationHistory[row].comment == 'None' ||
            this.validationHistory[row].comment == 'auto = default value'
          ) {
            this.validationHistory[row].comment = '';
          }
          // format validator
          if (this.validationHistory[row].typeValidation == 'True') {
            this.validationHistory[row].validator = 'Attribution automatique';
          }
        }
      },
      err => {
        console.log(err);
        if (err.status === 500) {
          // show error message if other server error
          this._commonService.translateToaster('error', err.error);
        }
      },
      () => {
        //console.log(this.statusNames);
      }
    );
  }

  backToModule(url_source, id_pk_source) {
    window.open(url_source + '/' + id_pk_source, '_blank');
  }
}
