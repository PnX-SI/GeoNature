import { Component, Input, OnInit, OnDestroy } from "@angular/core";
import { FormControl, FormGroup, FormArray, Validators } from "@angular/forms";
import { Subscription } from "rxjs/Subscription";
import { MapService } from "@geonature_common/map/map.service";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { OcctaxFormService } from "../occtax-form.service";
import { ViewEncapsulation } from "@angular/core";
import { ModuleConfig } from "../../../module.config";
import { DateStruc } from "@geonature_common/form/date.component";

@Component({
  selector: "pnx-releve",
  templateUrl: "releve.component.html",
  styleUrls: ["./releve.component.scss"],
  encapsulation: ViewEncapsulation.None
})
export class ReleveComponent implements OnInit, OnDestroy {
  @Input()
  releveForm: FormGroup;
  public dateMin: Date;
  public dateMax: Date;
  public geojson: any;
  public dataSets: any;
  public geoInfo: any;
  public showTime: boolean = false;
  public today: DateStruc;
  public areasIntersected = new Array();
  public occtaxConfig: any;
  private geojsonSubscription$: Subscription;

  constructor(
    private _ms: MapService,
    private _dfs: DataFormService,
    public fs: OcctaxFormService
  ) {}

  ngOnInit() {
    this.occtaxConfig = ModuleConfig;

    // subscription to the geojson observable
    this.geojsonSubscription$ = this._ms.gettingGeojson$.subscribe(geojson => {
      this.releveForm.patchValue({ geometry: geojson.geometry });
      this.geojson = geojson;
      // get to geo info from API
      this._dfs.getGeoInfo(geojson).subscribe(res => {
        this.releveForm.controls.properties.patchValue({
          altitude_min: res.altitude.altitude_min,
          altitude_max: res.altitude.altitude_max
        });
      });
      this._dfs.getFormatedGeoIntersection(geojson).subscribe(res => {
        this.areasIntersected = res;
      });
    });

    // set today for the datepicker limit
    const today = new Date();
    this.today = {
      year: today.getFullYear(),
      month: today.getMonth() + 1,
      day: today.getDate()
    };

    this.autoCompleteDate();
  } // END INIT

  autoCompleteDate() {
    // date max autocomplete
    (this.releveForm.controls.properties as FormGroup)
      .controls.date_min.valueChanges.subscribe(
        newvalue => {
          //Get mindate and maxdate value before mindate change
          let oldmindate = (this.releveForm.controls.properties as FormGroup).value['date_min'];
          let oldmaxdate = (this.releveForm.controls.properties as FormGroup).value['date_max'];
          //Compare the dates before the change of the datemin. If datemin and datemax were equal, maintain this equality
          //If they don't, do nothing
          //oldmaxdate and oldmindate are objects. Strigify it for a right comparison
          if (oldmindate){
            if (JSON.stringify(oldmaxdate) == JSON.stringify(oldmindate) || oldmaxdate == null) {
              this.releveForm.controls.properties.patchValue({ date_max: newvalue })
            }
          };
      }
    );
  }

  toggleTime() {
    this.showTime = !this.showTime;
  }

  ngOnDestroy() {
    this.geojsonSubscription$.unsubscribe();
  }
}
