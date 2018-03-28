import { Component, Input, OnInit, OnDestroy } from "@angular/core";
import { FormControl, FormGroup, FormArray, Validators } from "@angular/forms";
import { Subscription } from "rxjs/Subscription";
import { MapService } from "@geonature_common/map/map.service";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { CommonService } from "@geonature_common/service/common.service";
import { ContactFormService } from "../contact-form.service";
import { ViewEncapsulation } from "@angular/core";
import {
  NgbDateStruct,
  NgbDateParserFormatter
} from "@ng-bootstrap/ng-bootstrap";
import { NgbModal, ModalDismissReasons } from "@ng-bootstrap/ng-bootstrap";
import { OccTaxConfig } from "../../../occtax.config";

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
  public today: NgbDateStruct;
  public areasIntersected = new Array();
  public occtaxConfig: any;
  private geojsonSubscription$: Subscription;

  constructor(
    private _ms: MapService,
    private _dfs: DataFormService,
    public fs: ContactFormService,
    private _commonService: CommonService,
    private modalService: NgbModal,
    private _dateFormater: NgbDateParserFormatter
  ) {}

  ngOnInit() {
    this.occtaxConfig = OccTaxConfig;

    // subscription to the geojson observable
    this.geojsonSubscription$ = this._ms.gettingGeojson$.subscribe(geojson => {
      this.releveForm.patchValue({ geometry: geojson.geometry });
      this.geojson = geojson;
      // subscribe to geo info
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
    (this.releveForm.controls
      .properties as FormGroup).controls.date_min.valueChanges.subscribe(
      value => {
        if (this.releveForm.value.properties.date_max === null) {
          this.releveForm.controls.properties.patchValue({ date_max: value });
        }
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
