import { Component, OnInit, Output, EventEmitter } from '@angular/core';
import { DataService } from '../services/data.service';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { CommonService } from '@geonature_common/service/common.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { ValidationSyntheseListComponent } from './validation-synthese-list/validation-synthese-list.component';
import { ValidationSyntheseCarteComponent } from './validation-synthese-carte/validation-synthese-carte.component';
//import { SyntheseModalDownloadComponent } from './synthese-results/synthese-list/modal-download/modal-download.component';
import { AppConfig } from '@geonature_config/app.config';
import { ToastrService } from 'ngx-toastr'
import { ModuleConfig } from '../module.config';
import { ValidationSearchComponent } from './validation-search/validation-search.component'
import { FormService } from '../services/form.service';


@Component({
  selector: 'pnx-validation',
  styleUrls: ['validation.component.scss'],
  templateUrl: 'validation.component.html'
})


export class ValidationComponent implements OnInit {

  public serverData;
  public sameCoordinates: any;
  public statusNames;
  public statusKeys;
  public VALIDATION_CONFIG = ModuleConfig;

  //public syntheseConfig = AppConfig.SYNTHESE;
  @Output() searchClicked = new EventEmitter();


  constructor(
    public _ds: DataService,
    private _mapListService: MapListService,
    private _commonService: CommonService,
    private toastr: ToastrService,
    private _fs: FormService,
  ) {}


  ngOnInit() {
    this.getStatusNames();
  }


  getStatusNames() {

    this._ds.getStatusNames().subscribe(
      result => {
        // get status names
        this.statusNames = result;
        this.statusKeys = Object.keys(this.VALIDATION_CONFIG.STATUS_INFO);
      },
      err => {
        if (err.statusText === 'Unknown Error') {
          // show error message if no connexion
          this.toastr.error('ERROR: IMPOSSIBLE TO CONNECT TO SERVER (check your connexion)');
        } else {
          // show error message if other server error
          this.toastr.error(err.error);
        }
      },
      () => {
        const initialData = {}
        this.loadAndStoreData(initialData);
      }
    );

  }


  loadAndStoreData(formatedParams) {
    this._ds.dataLoaded = false;
    this._ds.getSyntheseData(formatedParams).subscribe(
      result => {
        //console.log(result);
        this._mapListService.geojsonData = result['data'];
        this._mapListService.loadTableData(result['data'], this.customColumns.bind(this));
        this._mapListService.idName = 'id_synthese';

        this._ds.dataLoaded = true;
        this.serverData = result['data'];
      },
      err => {
        if (err.statusText === 'Unknown Error') {
          // show error message if no connexion
          this.toastr.error('ERROR: IMPOSSIBLE TO CONNECT TO SERVER (check your connexion)');
        } else {
          // show error message if other server error
          this.toastr.error(err.error);
        }
      },
      () => {
      }
    );
  }


  mooveButton() {
    this.searchBarHidden = !this.searchBarHidden;
    // const test = document.getElementById('sidebar');
    // if (test.classList.contains('show')) {
    //   this.marginButton = 0;
    // } else {
    //   this.marginButton = 248;
    // }
  }


  formatDate(unformatedDate) {
    const date = new Date(unformatedDate);
    return date.toLocaleDateString('fr-FR');
  }


  customColumns(feature) {
    // function pass to the LoadTableData maplist service function to format date
    if (feature.properties.validation_auto === true) {
      feature.properties.validation_auto = this.VALIDATION_CONFIG.ICON_FOR_AUTOMATIC_VALIDATION;
    }
    if (feature.properties.validation_auto === false) {
      feature.properties.validation_auto = '';
    }
    if (feature.properties.date_min) {
      feature.properties.date_min = this.formatDate(feature.properties.date_min);
    }
    if (feature.properties.date_max) {
      feature.properties.date_max = this.formatDate(feature.properties.date_max);
    }
    return feature;
  }
  
}

