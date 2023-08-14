import { Component, OnInit, OnDestroy } from "@angular/core";
import { UntypedFormGroup } from "@angular/forms";
import { ActivatedRoute } from "@angular/router";
import { GeoJSON } from "leaflet";
import { Subscription } from "rxjs";
import { map, filter } from "rxjs/operators";
import { CommonService } from "@geonature_common/service/common.service";
import { OcctaxFormService } from "../occtax-form.service";
import { OcctaxFormReleveService } from "./releve.service";
import { OcctaxFormMapService } from "../map/occtax-map.service";
import { ModuleService } from "@geonature/services/module.service";
import { OcctaxDataService } from "../../services/occtax-data.service";
import { ConfigService } from "@geonature/services/config.service";
import { FormService as GlobalFormService } from "@geonature_common/form/form.service";

@Component({
  selector: "pnx-occtax-form-releve",
  templateUrl: "releve.component.html",
  styleUrls: ["./releve.component.scss"],
  providers: [],
})
export class OcctaxFormReleveComponent implements OnInit, OnDestroy {
  public get geojson(): GeoJSON {
    return this.occtaxFormMapService.geojson.getValue();
  }
  public userDatasets: Array<any>;
  public releveForm: UntypedFormGroup;
  public routeSub: Subscription;
  private _subscriptions: Subscription[] = [];
  public moduleConfig;

  get additionalFieldsForm(): any[] {
    return this.occtaxFormReleveService.additionalFieldsForm;
  }

  constructor(
    private route: ActivatedRoute,
    public occtaxFormService: OcctaxFormService,
    public occtaxFormReleveService: OcctaxFormReleveService,
    private occtaxFormMapService: OcctaxFormMapService,
    private commonService: CommonService,
    public moduleService: ModuleService,
    public occtaxDataService: OcctaxDataService,
    public config: ConfigService,
    public globalFormService: GlobalFormService,
    private _ds: OcctaxDataService,
  ) {}

  ngOnInit() {
    this.moduleConfig = this._ds.moduleConfig;

    this.releveForm = this.occtaxFormReleveService.releveForm;
    // pass route to releve.service to navigate
    this.occtaxFormReleveService.route = this.route;
    this.initHabFormSub();

    // if id_dataset pass as query parameters, pass it to the releve service in the form
    this._subscriptions.push(
      this.route.queryParams.subscribe((params) => {
        let datasetId = params["id_dataset"];
        if (datasetId) {
          this.occtaxFormReleveService.datasetId = datasetId;
        }
      }),
    );
  } // END INIT

  get dataset(): any {
    const occtaxData = this.occtaxFormService.occtaxData.getValue();
    if (occtaxData && occtaxData.releve.properties.dataset) {
      return occtaxData.releve.properties.dataset;
    }
    return null;
  }

  get propertiesForm(): any {
    return this.releveForm.get("properties");
  }

  formatter(item) {
    return item.search_name;
  }

  initHabFormSub() {
    // set current cd_hab to the releve form
    this._subscriptions.push(
      this.occtaxFormReleveService.habitatForm.valueChanges
        .pipe(
          filter((hab) => hab !== null),
          map((hab: any): number => {
            if (hab.cd_hab !== undefined && Number.isInteger(hab.cd_hab)) {
              return hab.cd_hab;
            }
            return null;
          }),
        )
        .subscribe((cd_hab) => {
          this.releveForm.get("properties").get("cd_hab").setValue(cd_hab);
        }),
    );
  }

  isDatasetUser(id_dataset: number = null): boolean {
    if (id_dataset === null || this.userDatasets === undefined) {
      return true;
    }

    for (let i = 0; i < this.userDatasets.length; i++) {
      if (this.userDatasets[i].id_dataset == id_dataset) {
        return true;
      }
    }

    return false;
  }

  ngOnDestroy() {
    this.occtaxFormReleveService.reset();
    this._subscriptions.forEach((s) => {
      s.unsubscribe();
    });
  }

  formDisabled() {
    if (this.occtaxFormService.disabled) {
      this.commonService.translateToaster(
        "warning",
        "Releve.FillGeometryFirst",
      );
    }
  }

  submitReleveForm() {
    if (this.releveForm.valid) {
      this.occtaxFormReleveService.submitReleve();
    }
  }
}
