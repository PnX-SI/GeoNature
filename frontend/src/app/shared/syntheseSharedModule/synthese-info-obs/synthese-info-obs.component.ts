import { Component, OnInit, Input, ViewChild, AfterViewInit } from '@angular/core';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { MapService } from '@geonature_common/map/map.service';
import { CommonService } from '@geonature_common/service/common.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { AppConfig } from '@geonature_config/app.config';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { MediaService } from '@geonature_common/service/media.service';
import { finalize } from 'rxjs/operators';
import { Color, BaseChartDirective } from "ng2-charts";
import { ChartDataSets, ChartOptions, ChartType } from 'chart.js';
import { AppConfig } from "@geonature_config/app.config"



import { MapComponent } from '@geonature_common/map/map.component'
import { TriStateCheckbox } from 'primeng/primeng';

@Component({
  selector: 'pnx-synthese-info-obs',
  templateUrl: 'synthese-info-obs.component.html',
  styleUrls: ['./synthese-info-obs.component.scss'],
  providers: [MapService]
})
export class SyntheseInfoObsComponent implements OnInit, AfterViewInit {
  @Input() idSynthese: number;
  @Input() header: boolean = false;
  @Input() mailCustomSubject: String;
  @Input() mailCustomBody: String;

  public selectedObs: any;
  public validationHistory: Array<any>;
  public selectedObsTaxonDetail: any;
  @ViewChild(BaseChartDirective) myChart: BaseChartDirective;
  public APP_CONFIG = AppConfig;
  public selectedGeom;
  public chartType = 'line';
  public profileDataChecks: any;


  public results: ChartDataSets[] = [
    { data: [], label: 'Altitude minimale extrême' },
    { data: [], label: 'Altitude minimale valide' },
    { data: [], label: 'Altitude maximale extrême' },
    { data: [], label: 'Altitude maximale valide' }
  ]

  public lineChartLabels: Label[] = [];

  // public lineChartOptions: (ChartOptions & { annotation: any }) = {
  //   responsive: true,
  //   scales: {
  //     // We use this empty structure as a placeholder for dynamic theming.
  //     xAxes: [{}],
  //     yAxes: [
  //       {
  //         id: 'y-axis-0',
  //         position: 'left',
  //       }
  //     ]
  //   },
  //   annotation: {
  //     annotations: [
  //       {
  //         type: 'line',
  //         mode: 'vertical',
  //         scaleID: 'x-axis-0',
  //         value: 'March',
  //         borderColor: 'orange',
  //         borderWidth: 2,
  //         label: {
  //           enabled: true,
  //           fontColor: 'orange',
  //           content: 'LineAnno'
  //         }
  //       },
  //     ],
  //   },
  // };

  public lineChartColors: Color[] = [
    { // grey
      backgroundColor: 'rgba(148,159,177,0.2)',
      borderColor: 'rgba(148,159,177,1)',
      pointBackgroundColor: 'rgba(148,159,177,1)',
      pointBorderColor: '#fff',
      pointHoverBackgroundColor: '#fff',
      pointHoverBorderColor: 'rgba(148,159,177,0.8)'
    },
    { // dark grey
      backgroundColor: 'rgba(77,83,96,0.2)',
      borderColor: 'rgba(77,83,96,1)',
      pointBackgroundColor: 'rgba(77,83,96,1)',
      pointBorderColor: '#fff',
      pointHoverBackgroundColor: '#fff',
      pointHoverBorderColor: 'rgba(77,83,96,1)'
    },
    { // red
      backgroundColor: null,
      borderColor: 'red',
      pointBackgroundColor: 'rgba(148,159,177,1)',
      pointBorderColor: '#fff',
      pointHoverBackgroundColor: '#fff',
      pointHoverBorderColor: 'rgba(148,159,177,0.8)'
    }
  ];
  public lineChartLegend = true;
  public lineChartType: ChartType = 'line';
  @ViewChild(BaseChartDirective) chart: BaseChartDirective;

  public selectObsTaxonInfo;
  public formatedAreas = [];
  public CONFIG = AppConfig;
  public isLoading = false;
  public email;
  public mailto: String;

  public APP_CONFIG = AppConfig;

  public profile: any;
  public phenology: any[];
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
    private _commonService: CommonService,
    private _mapService: MapService
  ) { }

  ngOnInit() {
    this.loadAllInfo(this.idSynthese);
  }

  ngAfterViewInit() {
    //this.chart.chart.update();
  }


  changeMapSize() {
    setTimeout(() => {
      this._mapService.map.invalidateSize();
    }, 500);
    
  }

  loadAllInfo(idSynthese) {
    this.isLoading = true;
    this._dataService
      .getOneSyntheseObservation(idSynthese)
      .pipe(
        finalize(() => {
          this.isLoading = false;
        })
      )
      .subscribe(data => {
        this.selectedObs = data["properties"];
        this.selectedGeom = data;
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
          .getTaxonAttributsAndMedia(this.selectedObs.cd_nom, AppConfig.SYNTHESE.ID_ATTRIBUT_TAXHUB)
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

          this._gnDataService.getProfile(taxInfo.cd_ref).subscribe(profile => {
            this.profile = profile;
          });

          this._gnDataService.getPhenology(taxInfo.cd_ref, this.selectedObs.id_nomenclature_life_stage).subscribe(phenology => {
            this.phenology = phenology;
            for (let i = 0; i <= phenology.length - 1; i++) {
              console.log(this.phenology[i])
              this.results[0].data.push(this.phenology[i].extreme_altitude_min)
              this.results[1].data.push(this.phenology[i].calculated_altitude_min)
              this.results[2].data.push(this.phenology[i].extreme_altitude_max)
              this.results[3].data.push(this.phenology[i].calculated_altitude_max)
              this.lineChartLabels.push(this.phenology[i].period)
            }
            //this.myChart.chart.update();
            // [
            // { data: [65, 59, 80, 81, 56, 55, 40], label: 'Series A' },
            // { data: [28, 48, 40, 19, 86, 27, 90], label: 'Series B' },
            // { data: [180, 480, 770, 90, 1000, 270, 400], label: 'Series C', yAxisID: 'y-axis-1' }
            // ]
          });
        });
      });

    this._gnDataService.getProfileConsistancyData(this.idSynthese).subscribe(dataChecks => {
      this.profileDataChecks = dataChecks;
    })
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

  loadProfile(cdRef) {
    this._gnDataService.getProfile(cdRef).subscribe(
      data => {
        this.profile = data;

      },
      err => {
        console.log(err);
        if (err.status === 404) {
          this._commonService.translateToaster('warning', 'Aucun profile');
        } else if (err.statusText === 'Unknown Error') {
          // show error message if no connexion
          this._commonService.translateToaster(
            'error',
            'ERROR: IMPOSSIBLE TO CONNECT TO SERVER (check your connection)'
          );
        } else {
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