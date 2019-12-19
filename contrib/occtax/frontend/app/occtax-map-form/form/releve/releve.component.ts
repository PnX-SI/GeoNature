import { Component, Input, OnInit, OnDestroy } from "@angular/core";
import { FormGroup } from "@angular/forms";
import { Subscription } from "rxjs/Subscription";
import { MapService } from "@geonature_common/map/map.service";
import { FormService } from "@geonature_common/form/form.service";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { OcctaxFormService } from "../occtax-form.service";
import { ViewEncapsulation } from "@angular/core";
import { ModuleConfig } from "../../../module.config";
import { DateStruc } from "@geonature_common/form/date/date.component";
import { filter } from "rxjs/operators";

@Component({
  selector: "pnx-releve",
  templateUrl: "releve.component.html",
  styleUrls: ["./releve.component.scss"],
  encapsulation: ViewEncapsulation.None
})
export class ReleveComponent implements OnInit, OnDestroy {
  @Input() releveForm: FormGroup;
  public dateMin: Date;
  public dateMax: Date;
  public geojson: any;
  public dataSets: any;
  public geoInfo: any;
  public showTime: boolean = false;
  public today: DateStruc = null;
  public areasIntersected = new Array();
  public occtaxConfig: any;
  private geojsonSubscription$: Subscription;
  public isEditionSub$: Subscription;

  constructor(
    private _ms: MapService,
    private _dfs: DataFormService,
    public fs: OcctaxFormService,
    private _commonFormService: FormService
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
    if (ModuleConfig.DATE_FORM_WITH_TODAY) {
      const today = new Date();
      this.today = {
        year: today.getFullYear(),
        month: today.getMonth() + 1,
        day: today.getDate()
      };
    }

    // Autocomplete date only if its not edition MODE
    this.isEditionSub$ = this.fs.editionMode$
      .pipe(filter(isEdit => isEdit === false))
      .subscribe(isEdit => {
        if (isEdit === false) {
          this._commonFormService.autoCompleteDate(
            this.releveForm.controls.properties as FormGroup
          );
        }
      });

    // autcomplete hourmax + set null when empty
    (this.releveForm.controls
      .properties as FormGroup).controls.hour_min.valueChanges
      .pipe(filter(value => value != null))
      .subscribe(value => {
        if (value.length == 0) {
          (this.releveForm.controls
            .properties as FormGroup).controls.hour_min.reset();
        } else if (
          // autcomplete only if hour max is empty or invalid
          (this.releveForm.controls.properties as FormGroup).controls.hour_max
            .invalid ||
          this.releveForm.value.properties.hour_max == null
        ) {
          if (!this.fs.currentHourMax) {
            // autcomplete hour max only if currentHourMax is null
            (this.releveForm.controls
              .properties as FormGroup).controls.hour_max.patchValue(value);
          }
        }
      });

    // set hour_max = hour_min to prevent date_max<date_min
    (this.releveForm.controls
      .properties as FormGroup).controls.hour_max.valueChanges
      .pipe(filter(value => value != null))
      .subscribe(value => {
        if (value.length == 0)
          (this.releveForm.controls
            .properties as FormGroup).controls.hour_max.reset();
      });
  } // END INIT

  toggleTime() {
    this.showTime = !this.showTime;
  }

  ngOnDestroy() {
    this.geojsonSubscription$.unsubscribe();
    this.isEditionSub$.unsubscribe();
  }
}
