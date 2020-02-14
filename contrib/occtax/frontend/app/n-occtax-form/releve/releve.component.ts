import { Component, Input, OnInit, OnDestroy } from "@angular/core";
import { FormGroup } from "@angular/forms";
import { GeoJSON } from "leaflet";
import { ModuleConfig } from "../../module.config";
import { CommonService } from "@geonature_common/service/common.service";
import { OcctaxFormService } from "../occtax-form.service";
import { OcctaxFormReleveService } from "./releve.service";
import { OcctaxFormMapService } from "../map/map.service";

@Component({
  selector: "pnx-occtax-form-releve",
  templateUrl: "releve.component.html",
  styleUrls: ["./releve.component.scss"]
})
export class OcctaxFormReleveComponent implements OnInit, OnDestroy {

  // @Input() releveForm: FormGroup;
  // public dateMin: Date;
  // public dateMax: Date;
  // public geojson: any;
  // public dataSets: any;
  // public geoInfo: any;
  // public showTime: boolean = false;
  // public today: DateStruc = null;
  // public areasIntersected = new Array();
  // private geojsonSubscription$: Subscription;
  // public isEditionSub$: Subscription;
  public releveForm: FormGroup;
  public occtaxConfig: any;
  public geojson: GeoJSON;

  constructor(
    public occtaxFormService: OcctaxFormService,
    private occtaxFormReleveService: OcctaxFormReleveService,
    private occtaxFormMapService: OcctaxFormMapService,
    private commonService: CommonService
  ) {
    this.occtaxConfig = ModuleConfig;
  }

  ngOnInit() {
    this.releveForm = this.occtaxFormReleveService.form;

    this.occtaxFormMapService.geojson
                    .subscribe(geojson=>this.geojson = geojson);
    // this.occtaxConfig = ModuleConfig;
    // // subscription to the geojson observable
    // this.geojsonSubscription$ = this._ms.gettingGeojson$.subscribe(geojson => {

    //   this._dfs.getFormatedGeoIntersection(geojson).subscribe(res => {
    //     this.areasIntersected = res;
    //   });
    // });

    // // autcomplete hourmax + set null when empty
    // (this.releveForm.controls
    //   .properties as FormGroup).controls.hour_min.valueChanges
    //   .pipe(filter(value => value != null))
    //   .subscribe(value => {
    //     if (value.length == 0) {
    //       (this.releveForm.controls
    //         .properties as FormGroup).controls.hour_min.reset();
    //     } else if (
    //       // autcomplete only if hour max is empty or invalid
    //       (this.releveForm.controls.properties as FormGroup).controls.hour_max
    //         .invalid ||
    //       this.releveForm.value.properties.hour_max == null
    //     ) {
    //       if (!this.fs.currentHourMax) {
    //         // autcomplete hour max only if currentHourMax is null
    //         (this.releveForm.controls
    //           .properties as FormGroup).controls.hour_max.patchValue(value);
    //       }
    //     }
    //   });

    // // set hour_max = hour_min to prevent date_max<date_min
    // (this.releveForm.controls
    //   .properties as FormGroup).controls.hour_max.valueChanges
    //   .pipe(filter(value => value != null))
    //   .subscribe(value => {
    //     if (value.length == 0)
    //       (this.releveForm.controls
    //         .properties as FormGroup).controls.hour_max.reset();
    //   });
  } // END INIT

  get dataset(): any {
    let occtaxData = this.occtaxFormService.occtaxData.getValue();
    if (occtaxData && occtaxData.releve.properties.dataset) {
      return occtaxData.releve.properties.dataset;
    }
    return null;
  }

  toggleTime() {
    // this.showTime = !this.showTime;
  }

  ngOnDestroy() {
    console.log("destroy");
    this.occtaxFormReleveService.reset();
    // this.geojsonSubscription$.unsubscribe();
    // this.isEditionSub$.unsubscribe();
  }

  formDisabled() {
    if (this.occtaxFormService.disabled) {
      this.commonService.translateToaster(
        "warning",
        "Releve.FillGeometryFirst"
      );
    }
  }
}
