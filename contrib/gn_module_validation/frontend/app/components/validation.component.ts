import { Component, OnInit } from "@angular/core";
import { ValidationDataService } from "../services/data.service";
import { ActivatedRoute, Router } from "@angular/router";
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
  public sameCoordinates: string;
  public validationStatus;
  public searchBarHidden: boolean = true;
  public idSynthese: any;

  constructor(
    private _route: ActivatedRoute,
    private _router: Router,
    public _ds: ValidationDataService,
    public _mapListService: MapListService,
    private _commonService: CommonService,
    private _fs: SyntheseFormService
  ) { }

  ngOnInit() {
    // reinitialize the form
    this._fs.searchForm.reset();
    this._fs.selectedCdRefFromTree = [];
    this._fs.selectedTaxonFromRankInput = [];
    this._fs.selectedtaxonFromComponent = [];
    this.getStatusNames();
    this._commonService.translateToaster("info", "La limite de nombre d'observations affichable dans le module est de " +
      ModuleConfig.NB_MAX_OBS_MAP);
    this._commonService.translateToaster("info", "Les 100 dernières observations");
    this.idSynthese = this._route.snapshot.paramMap.get("id_synthese");
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
        const initialData = { 'limit': 100 };

        this.loadAndStoreData(initialData);
      }
    );
  }

  loadAndStoreData(formatedParams) {
    if(this.idSynthese) {
      // filter data by search id
      formatedParams.id_synthese = this.idSynthese;
    }
    this._ds.dataLoaded = false;
    this._ds.getSyntheseData(formatedParams).subscribe(
      result => {
        this._mapListService.geojsonData = result;
        this._mapListService.loadTableData(
          result,
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
          this._commonService.translateToaster("error", err.error.description);
        }
        this._ds.dataLoaded = true;
      }
    );
  }

  // formatDate(unformatedDate) {
  //   const date = new Date(unformatedDate);
  //   return date.toLocaleDateString("fr-FR");
  // }

  customColumns(feature) {
    // function pass to the LoadTableData maplist service function to format date
    if (feature.properties.validation_auto === true) {
      feature.properties.validation_auto =
        ModuleConfig.ICON_FOR_AUTOMATIC_VALIDATION;
    }
    if (feature.properties.validation_auto === false) {
      feature.properties.validation_auto = "";
    }
    return feature;
  }

  goHome() {
    this._router.navigate(["/validation"]);
  }
}
