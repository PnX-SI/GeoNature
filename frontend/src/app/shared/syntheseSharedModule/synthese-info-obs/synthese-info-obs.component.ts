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
  @Input() header: boolean = false;
  @Input() mailCustomSubject: String;
  @Input() mailCustomBody: String;

  public selectedObs: any;
  public validationHistory: Array<any>;
  public selectedObsTaxonDetail: any;
  public selectObsTaxonInfo;
  public formatedAreas = [];
  public CONFIG = AppConfig;
  public isLoading = false;
  public email;
  public mailto: String;

  public APP_CONFIG = AppConfig;

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
  }

  ngOnChanges(changes) {
    // load releve only after first init
    if (changes.idSynthese && changes.idSynthese.currentValue && !changes.idSynthese.firstChange) {
      this.loadOneSyntheseReleve(this.idSynthese);
    }
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
        this.formatedAreas = [];
        for (let key in areaDict) {
          this.formatedAreas.push({ area_type: key, areas: areaDict[key] });
        }

        this._gnDataService
          .getTaxonAttributsAndMedia(data.cd_nom, AppConfig.SYNTHESE.ID_ATTRIBUT_TAXHUB)
          .subscribe(taxAttr => {
            this.selectObsTaxonInfo = taxAttr;
          });

        this.loadValidationHistory(this.selectedObs['unique_id_sinp']);
        this._gnDataService.getTaxonInfo(data.cd_nom).subscribe(taxInfo => {
          this.selectedObsTaxonDetail = taxInfo;
          if (this.selectedObs.cor_observers) {
            this.email = this.selectedObs.cor_observers.map(el => el.email).join();
            this.mailto = this.formatMailContent(this.email);
            
          }
        });
      });
  }

  formatMailContent(email) {
    let mailto = String('mailto:' + email);
    if (this.mailCustomSubject || this.mailCustomBody) {

      // Mise en forme des données
      let d = { ...this.selectedObsTaxonDetail, ...this.selectedObs };      
      if (this.selectedObs.source.url_source) {
        d['data_link'] = [
          this.APP_CONFIG.URL_APPLICATION,
          this.selectedObs.source.url_source,
          this.selectedObs.entity_source_pk_value
        ].join("/");
      }
      else {
        d['data_link'] = "";
      }
      
      d["communes"] = this.selectedObs.areas.filter(
        area => area.area_type.type_code == 'COM'
      ).map(
        area => area.area_name
      ).join(', ');
      
      let contentMedias = "";
      if (!this.selectedObs.medias) {
        contentMedias = "Aucun media";
      }
      else {
        if (this.selectedObs.medias.length == 0) {
          contentMedias = "Aucun media";
        }
        this.selectedObs.medias.map((media) => {
          contentMedias += "\n\tTitre : " + media.title_fr;
          contentMedias += "\n\tLien vers le media : " + this.mediaService.href(media);
          if (media.description_fr) {
            contentMedias += "\n\tDescription : " + media.description_fr;
          }
          if (media.author) {
            contentMedias += "\n\tAuteur : " + media.author;
          }
          contentMedias += "\n";
        })
      }
      d["medias"] = contentMedias;      
      // Construction du mail
      if (this.mailCustomSubject !== undefined) {
        try {
          mailto += "?subject=" + eval('`' + this.mailCustomSubject + '`');
        } catch (error) {
          console.log('ERROR : unable to eval mail subject');
        }
      }
      if (this.mailCustomBody !== undefined) {
        try {
          mailto += '&body=' + eval('`' + this.mailCustomBody + '`');
        } catch (error) {
          console.log('ERROR : unable to eval mail body');
        }
      }
      
      mailto = encodeURI(mailto);
      mailto = mailto.replace(/,/g, '%2c');
    }
    console.log(mailto);
    
    return mailto;
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