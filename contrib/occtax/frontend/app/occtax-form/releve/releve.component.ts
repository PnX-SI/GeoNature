import { Component, Input, OnInit, OnDestroy } from "@angular/core";
import { FormGroup, FormControl } from "@angular/forms";
import { ActivatedRoute } from "@angular/router";
import { GeoJSON } from "leaflet";
import { map, filter, tap } from "rxjs/operators";
import { ModuleConfig } from "../../module.config";
import { CommonService } from "@geonature_common/service/common.service";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { OcctaxFormService } from "../occtax-form.service";
import { OcctaxFormReleveService } from "./releve.service";
import { OcctaxFormMapService } from "../map/map.service";
import { AppConfig } from "@geonature_config/app.config";

@Component({
  selector: "pnx-occtax-form-releve",
  templateUrl: "releve.component.html",
  styleUrls: ["./releve.component.scss"],
})
export class OcctaxFormReleveComponent implements OnInit, OnDestroy {
  public occtaxConfig: any;
  public geojson: GeoJSON;
  public userDatasets: Array<any>;
  public releveForm: FormGroup;
  public AppConfig = AppConfig;

  constructor(
    private route: ActivatedRoute,
    public occtaxFormService: OcctaxFormService,
    private occtaxFormReleveService: OcctaxFormReleveService,
    private occtaxFormMapService: OcctaxFormMapService,
    private commonService: CommonService,
    private _dataService: DataFormService
  ) {
    this.occtaxConfig = ModuleConfig;
  }

  ngOnInit() {
    this.releveForm = this.occtaxFormReleveService.releveForm;
    this.initHabFormSub();
    // in order to pass data to the inserected area component
    this.occtaxFormMapService.geojson.subscribe(geojson => {
      this.geojson = geojson;
      // check if edition

    })

    this.occtaxFormReleveService.route = this.route;
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
    this.occtaxFormReleveService.habitatForm.valueChanges
      .pipe(
        filter((hab) => hab !== null),
        map((hab: any): number => {
          if (hab.cd_hab !== undefined && Number.isInteger(hab.cd_hab)) {
            return hab.cd_hab;
          }
          return null
        })
      ).subscribe(cd_hab => {
        this.releveForm.get('properties').get('cd_hab').setValue(cd_hab);
      });

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
  }

  formDisabled() {
    if (this.occtaxFormService.disabled) {
      this.commonService.translateToaster(
        "warning",
        "Releve.FillGeometryFirst"
      );
    }
  }

  submitReleveForm() {
    if (this.releveForm.valid) {
      this.occtaxFormReleveService.submitReleve();
    }
  }
}
