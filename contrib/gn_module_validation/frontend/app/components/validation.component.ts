import { Component, OnInit, Output, EventEmitter } from "@angular/core";
import { ValidationDataService } from "../services/data.service";

import { MapListService } from "@geonature_common/map-list/map-list.service";
import { CommonService } from "@geonature_common/service/common.service";
import { ModuleConfig } from "../module.config";
import { SyntheseFormService } from "@geonature_common/form/synthese-form/synthese-form.service";

@Component({
  selector: "pnx-validation",
  styleUrls: ["validation.component.scss"],
  templateUrl: "validation.component.html"
})
export class ValidationComponent implements OnInit {
  public sameCoordinates: any;
  public validationStatus;
  public searchBarHidden: boolean = true;

  constructor(
    public _ds: ValidationDataService,
    private _mapListService: MapListService,
    private _commonService: CommonService,
    private _fs: SyntheseFormService
  ) {}

  ngOnInit() {
    // reinitialize the form
    this._fs.searchForm.reset();
    this._fs.selectedCdRefFromTree = [];
    this._fs.selectedTaxonFromRankInput = [];
    this._fs.selectedtaxonFromComponent = [];
    this.getStatusNames();
    this._commonService.translateToaster("info", "Le nombre d'observations affiché sur la carte est limité à " +
        ModuleConfig.NB_MAX_OBS_MAP);
  }

  getStatusNames() {
    this._ds.getStatusNames().subscribe(
      result => {
        // get status names
        this.validationStatus = result;
        //this.validationStatus[0]
        // order item
        // put "en attente de la validation" at the end
        this.validationStatus.push(this.validationStatus[0]);
        // end remove it
        this.validationStatus.shift();
      },
      err => {
        if (err.statusText === "Unknown Error") {
          // show error message if no connexion
          this._commonService.translateToaster("error", "ERROR: IMPOSSIBLE TO CONNECT TO SERVER (check your connection)");
        } else {
          // show error message if other server error
          this._commonService.translateToaster("error", err.error);
        }
      },
      () => {
        const initialData = {};
        this.loadAndStoreData(initialData);
      }
    );
  }

  loadAndStoreData(formatedParams) {
    this._ds.dataLoaded = false;
    this._ds.getSyntheseData(formatedParams).subscribe(
      result => {
        this._mapListService.geojsonData = result["data"];
        this._mapListService.loadTableData(
          result["data"],
          this.customColumns.bind(this)
        );
        this._mapListService.idName = "id_synthese";

        this._ds.dataLoaded = true;
      },
      err => {
        if (err.statusText === "Unknown Error") {
          // show error message if no connexion
          this._commonService.translateToaster("error", "ERROR: IMPOSSIBLE TO CONNECT TO SERVER (check your connection)");
        } else {
          // show error message if other server error
          this._commonService.translateToaster("error", err.error);
        }
      },
      () => {}
    );
  }

  formatDate(unformatedDate) {
    const date = new Date(unformatedDate);
    return date.toLocaleDateString("fr-FR");
  }

  customColumns(feature) {
    // function pass to the LoadTableData maplist service function to format date
    if (feature.properties.validation_auto === true) {
      feature.properties.validation_auto =
        ModuleConfig.ICON_FOR_AUTOMATIC_VALIDATION;
    }
    if (feature.properties.validation_auto === false) {
      feature.properties.validation_auto = "";
    }
    if (feature.properties.date_min) {
      feature.properties.date_min = this.formatDate(
        feature.properties.date_min
      );
    }
    if (feature.properties.date_max) {
      feature.properties.date_max = this.formatDate(
        feature.properties.date_max
      );
    }
    return feature;
  }
}
