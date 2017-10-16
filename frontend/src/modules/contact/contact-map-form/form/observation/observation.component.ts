import { Component, Input, OnInit, OnDestroy } from '@angular/core';
import { FormControl, FormGroup, FormArray, Validators } from '@angular/forms';
import { Subscription } from 'rxjs/Subscription';
import { MapService } from '../../../../../core/GN2Common/map/map.service';
import { DataFormService } from '../../../../../core/GN2Common/form/data-form.service';
import { CommonService } from '../../../../../core/GN2Common/service/common.service';
import { ContactFormService } from '../contact-form.service';
import {ViewEncapsulation} from '@angular/core';
import {NgbDateStruct} from '@ng-bootstrap/ng-bootstrap';
import {NgbModal, ModalDismissReasons} from '@ng-bootstrap/ng-bootstrap';



@Component({
  selector: 'pnx-observation',
  templateUrl: 'observation.component.html',
  styleUrls: ['./observation.component.scss'],
  encapsulation: ViewEncapsulation.None
})

export class ObservationComponent implements OnInit, OnDestroy {
  @Input() releveForm: FormGroup;
  public dateMin: any;
  public dateMax: any;
  public bsRangeValue: any = [new Date(2017, 7, 4), new Date(2017, 7, 20)];
  public geojson: any;
  public dataSets: any;
  public geoInfo: any;
  public showTime: boolean = false;
  public today: NgbDateStruct;
  public areasIntersected = new Array();
  private geojsonSubscription$: Subscription;

  constructor(private _ms: MapService, private _dfs: DataFormService, public fs: ContactFormService,
  private _commonService: CommonService, private modalService: NgbModal) {  }

  ngOnInit() {
    // load datasets
    this._dfs.getDatasets()
      .subscribe(res => this.dataSets = res);
    // subscription to the geojson observable
    this.geojsonSubscription$ = this._ms.gettingGeojson$
      .subscribe(geojson => {
        this.releveForm.patchValue({geometry: geojson.geometry});
        this.geojson = geojson;
        // subscribe to geo info
        this._dfs.getGeoInfo(geojson)
          .subscribe(res => {
            this.releveForm.controls.properties.patchValue({
              altitude_min: res.altitude.altitude_min,
              altitude_max: res.altitude.altitude_max,
            });
          });
        this._dfs.getFormatedGeoIntersection(geojson)
          .subscribe(res => {
            this.areasIntersected = res;
            console.log(this.areasIntersected);
          });
      });

    // date max autocomplete
    (this.releveForm.controls.properties as FormGroup).controls.date_min.valueChanges
      .subscribe(value => {
        this.releveForm.controls.properties.patchValue({date_max: value});
      });
    // set today for the datepicker limit
    const today = new Date();
    this.today = { year: today.getFullYear(), month: today.getMonth() + 1, day: today.getDate() };

    // check if dateMax is not < dateMin
    (this.releveForm.controls.properties as FormGroup).controls.date_max.valueChanges
    .debounceTime(500)
    .subscribe(value => {
      let dateMin = this.releveForm.value.properties.date_min;
      if (dateMin) {
        dateMin = new Date(dateMin.year, dateMin.month, dateMin.day);
        const dateMax = new Date(value.year, value.month, value.day);
        if (dateMax < dateMin) {
          (this.releveForm.controls.properties as FormGroup).controls.date_max.setErrors([Validators.required]);
          this._commonService.translateToaster('error', 'Releve.DateMaxError');
        }
      }
    });
  }


  toggleTime() {
    this.showTime = !this.showTime;
  }

  dateChanged(date) {
    const newDate = new Date(date);
  }


  ngOnDestroy() {
    this.geojsonSubscription$.unsubscribe();
  }
}
