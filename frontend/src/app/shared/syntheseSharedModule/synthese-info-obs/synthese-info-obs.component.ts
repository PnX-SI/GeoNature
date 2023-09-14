import { Component, OnInit, OnChanges, Input, ViewChild, SimpleChanges } from '@angular/core';
import { Clipboard } from '@angular/cdk/clipboard';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { MapService } from '@geonature_common/map/map.service';
import { CommonService } from '@geonature_common/service/common.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { MediaService } from '@geonature_common/service/media.service';
import { finalize } from 'rxjs/operators';
import { isEmpty, find } from 'lodash';
import { ModuleService } from '@geonature/services/module.service';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-synthese-info-obs',
  templateUrl: 'synthese-info-obs.component.html',
  styleUrls: ['./synthese-info-obs.component.scss'],
  providers: [MapService],
})
export class SyntheseInfoObsComponent implements OnInit, OnChanges {
  @Input() idSynthese: number;
  @Input() header: false;
  @Input() mailCustomSubject: string;
  @Input() mailCustomBody: string;
  @Input() useFrom: 'synthese' | 'validation';
  public selectedObs: any;
  public validationHistory: Array<any> = [];
  public selectedObsTaxonDetail: any;
  @ViewChild('tabGroup') tabGroup;
  public selectedGeom;
  // public chartType = 'line';
  public profileDataChecks: any;
  public showValidation = false;

  public selectObsTaxonInfo;
  public selectCdNomenclature;
  public formatedAreas = [];
  public isLoading = false;
  public email;
  public mailto: string;
  public moduleInfos: any;

  public profile: any;
  public phenology: any[];
  public alertOpen: boolean;
  public alert;
  public pin;
  public activateAlert = false;
  public activatePin = false;
  public validationColor = {
    '0': '#FFFFFF',
    '1': '#8BC34A',
    '2': '#CDDC39',
    '3': '#FF9800',
    '4': '#FF5722',
    '5': '#BDBDBD',
    '6': '#FFFFFF',
  };
  public comment: string;
  constructor(
    private _gnDataService: DataFormService,
    private _dataService: SyntheseDataService,
    public activeModal: NgbActiveModal,
    public mediaService: MediaService,
    private _commonService: CommonService,
    private _mapService: MapService,
    private _clipboard: Clipboard,
    private _moduleService: ModuleService,
    public config: ConfigService
  ) {}

  ngOnInit() {
    this.loadAllInfo(this.idSynthese);
    this._moduleService.currentModule$.subscribe((module) => {
      if (module) {
        this.moduleInfos = { id: module.id_module, code: module.module_code };
        this.activateAlert = this.config.SYNTHESE.ALERT_MODULES.includes(this.moduleInfos?.code);
        this.activatePin = this.config.SYNTHESE.PIN_MODULES.includes(this.moduleInfos?.code);
      }
    });
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes.idSynthese && changes.idSynthese.currentValue) {
      this.loadAllInfo(changes.idSynthese.currentValue);
    }
  }

  // HACK to display a second map on validation tab
  setValidationTab() {
    this.showValidation = true;
    if (this._mapService.map) {
      setTimeout(() => {
        this._mapService.map.invalidateSize();
      }, 100);
    }
  }

  loadAllInfo(idSynthese) {
    this.isLoading = true;
    this.getReport('pin');
    this._dataService
      .getOneSyntheseObservation(idSynthese)
      .pipe(
        finalize(() => {
          this.isLoading = false;
        })
      )
      .subscribe((data) => {
        this.selectedObs = data['properties'];
        this.alert = find(data.properties.reports, ['report_type.type', 'alert']);
        this.selectCdNomenclature = this.selectedObs?.nomenclature_valid_status.cd_nomenclature;
        this.selectedGeom = data;
        this.selectedObs['municipalities'] = [];
        this.selectedObs['other_areas'] = [];
        const date_min = new Date(this.selectedObs.date_min);
        this.selectedObs.date_min = date_min.toLocaleDateString('fr-FR');
        const date_max = new Date(this.selectedObs.date_max);
        this.selectedObs.date_max = date_max.toLocaleDateString('fr-FR');

        const areaDict = {};
        // for each area type we want all the areas: we build an dict of array
        if (this.selectedObs.areas) {
          this.selectedObs.areas.forEach((area) => {
            if (!areaDict[area.area_type.type_name]) {
              areaDict[area.area_type.type_name] = [area];
            } else {
              areaDict[area.area_type.type_name].push(area);
            }
          });
        }

        // for angular tempate we need to convert it into a aray
        // eslint-disable-next-line guard-for-in
        this.formatedAreas = [];
        for (const key in areaDict) {
          this.formatedAreas.push({ area_type: key, areas: areaDict[key] });
        }

        this._gnDataService
          .getTaxonAttributsAndMedia(
            this.selectedObs.cd_nom,
            this.config.SYNTHESE.ID_ATTRIBUT_TAXHUB
          )
          .subscribe((taxAttr) => {
            this.selectObsTaxonInfo = taxAttr;
          });

        if (this.selectedObs['unique_id_sinp']) {
          this.loadValidationHistory(this.selectedObs['unique_id_sinp']);
        }
        let cdNom = this.selectedObs['cd_nom'];
        let areasStatus = this.selectedObs['areas'].map((area) => area.id_area);
        this._gnDataService.getTaxonInfo(cdNom, areasStatus).subscribe((taxInfo) => {
          this.selectedObsTaxonDetail = taxInfo;
          if (this.selectedObs.cor_observers) {
            this.email = this.selectedObs.cor_observers
              .map((el) => el.email)
              .filter((v) => v)
              .join();
            this.mailto = this.formatMailContent(this.email);
          }

          this._gnDataService.getProfile(taxInfo.cd_ref).subscribe((profile) => {
            this.profile = profile;
          });
        });
      });

    this._gnDataService.getProfileConsistancyData(this.idSynthese).subscribe((dataChecks) => {
      this.profileDataChecks = dataChecks;
    });
  }

  sendMail() {
    window.location.href = `${this.mailto}`;
  }

  formatMailContent(email) {
    let mailto = String('mailto:' + email);
    if (this.mailCustomSubject || this.mailCustomBody) {
      // Mise en forme des données
      const d = { ...this.selectedObsTaxonDetail, ...this.selectedObs };
      if (this.selectedObs.source.url_source) {
        d['data_link'] = [
          this.config.URL_APPLICATION,
          this.selectedObs.source.url_source,
          this.selectedObs.entity_source_pk_value,
        ].join('/');
      } else {
        d['data_link'] = '';
      }

      d['communes'] = this.selectedObs.areas
        .filter((area) => area.area_type.type_code === 'COM')
        .map((area) => area.area_name)
        .join(', ');

      let contentMedias = '';
      if (!this.selectedObs.medias) {
        contentMedias = 'Aucun media';
      } else {
        if (!this.selectedObs.medias.length) {
          contentMedias = 'Aucun media';
        }
        this.selectedObs.medias.map((media) => {
          contentMedias += '\n\tTitre : ' + media.title_fr;
          contentMedias += '\n\tLien vers le media : ' + this.mediaService.href(media);
          if (media.description_fr) {
            contentMedias += '\n\tDescription : ' + media.description_fr;
          }
          if (media.author) {
            contentMedias += '\n\tAuteur : ' + media.author;
          }
          contentMedias += '\n';
        });
      }
      d['medias'] = contentMedias;
      // Construction du mail
      if (this.mailCustomSubject !== undefined) {
        try {
          mailto += `?subject=${new Function('d', 'return ' + '`' + this.mailCustomSubject + '`')(
            d
          )}`;
        } catch (error) {}
      }
      if (this.mailCustomBody !== undefined) {
        try {
          mailto += `&body=${new Function('d', 'return ' + '`' + this.mailCustomBody + '`')(d)}`;
        } catch (error) {}
      }

      mailto = encodeURI(mailto);
      mailto = mailto.replace(/,/g, '%2c');
    }

    return mailto;
  }

  loadValidationHistory(uuid) {
    this._gnDataService.getValidationHistory(uuid).subscribe((data) => {
      this.validationHistory = data;
      // eslint-disable-next-line guard-for-in
      for (const row in this.validationHistory) {
        // format date
        const date = new Date(this.validationHistory[row].date);
        this.validationHistory[row].date = date.toLocaleDateString('fr-FR');
        this.validationHistory[row].dateTime = date;
        // format comments
        if (
          this.validationHistory[row].comment === 'None' ||
          this.validationHistory[row].comment === 'auto = default value'
        ) {
          this.validationHistory[row].comment = '';
        }
        // format validator
        if (this.validationHistory[row].typeValidation === 'True') {
          this.validationHistory[row].validator = 'Attribution automatique';
        }
      }
    });
  }

  loadProfile(cdRef) {
    this._gnDataService.getProfile(cdRef).subscribe(
      (data) => {
        this.profile = data;
      },
      (err) => {
        if (err.status === 404) {
          this._commonService.translateToaster('warning', 'Aucun profile');
        } else if (err.statusText === 'Unknown Error') {
          // show error message if no connexion
          this._commonService.translateToaster(
            'error',
            'ERROR: IMPOSSIBLE TO CONNECT TO SERVER (check your connection)'
          );
        }
      }
    );
  }

  backToModule(url_source, id_pk_source) {
    window.open(url_source + '/' + id_pk_source, '_blank');
  }

  /**
   * This GET is required to get id_report autogenerate on creation, and DELETE with id_report next.
   */
  getReport(type) {
    this._dataService
      .getReports(`idSynthese=${this.idSynthese}&type=${type}&sort=asc`)
      .subscribe((data) => {
        this[type] = data[0];
      });
  }

  openCloseAlert() {
    this.alertOpen = !this.alertOpen;
    // avoid useless request
    if (this.config.SYNTHESE?.ALERT_MODULES && this.config.SYNTHESE.ALERT_MODULES.length) {
      this.getReport('alert');
    }
  }

  alertExists() {
    return !isEmpty(this.alert);
  }

  pinExists() {
    return !isEmpty(this.pin);
  }

  /**
   * Create only one pin by user by id_synthese.
   * Only owner car delete or create pin for himself.
   */
  addPin() {
    this._dataService
      .createReport({
        type: 'pin',
        item: this.idSynthese,
        content: '',
      })
      .subscribe(() => {
        this._commonService.translateToaster('success', 'Epinglé !');
        this.getReport('pin');
      });
  }

  deletePin() {
    this._dataService.deleteReport(this.pin.id_report).subscribe(() => {
      this._commonService.translateToaster('info', 'Epingle supprimée !');
      this.pin = {};
    });
  }

  /**
   * Manage click action on pin button to add or delete pin
   */
  pinSelectedObs() {
    if (isEmpty(this.pin)) {
      this.addPin();
    } else {
      this.deletePin();
    }
  }

  copyToClipBoard() {
    this._clipboard.copy(
      `${this.config.URL_APPLICATION}/#/${this.useFrom}/occurrence/${this.selectedObs.id_synthese}`
    );
    this._commonService.translateToaster('info', 'Synthese.copy');
  }
}
