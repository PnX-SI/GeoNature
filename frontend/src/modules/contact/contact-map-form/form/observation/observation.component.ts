import { Component, Input, OnInit, OnDestroy } from '@angular/core';
import { FormControl, FormGroup, FormArray, Validators } from '@angular/forms';
import { Subscription } from 'rxjs/Subscription';
import { MapService } from '../../../../../core/GN2Common/map/map.service';
import { DataFormService } from '../../../../../core/GN2Common/form/data-form.service';
import { CommonService } from '../../../../../core/GN2Common/service/common.service';
import { ContactFormService } from '../contact-form.service';
import {ViewEncapsulation} from '@angular/core';
import {NgbDateStruct, NgbDateParserFormatter} from '@ng-bootstrap/ng-bootstrap';
import {NgbModal, ModalDismissReasons} from '@ng-bootstrap/ng-bootstrap';
import { ContactConfig } from '../../../contact.config';


@Component({
  selector: 'pnx-observation',
  templateUrl: 'observation.component.html',
  styleUrls: ['./observation.component.scss'],
  encapsulation: ViewEncapsulation.None
})

export class ObservationComponent implements OnInit, OnDestroy {
  @Input() releveForm: FormGroup;
  public dateMin: Date;
  public dateMax: Date;
  public geojson: any;
  public dataSets: any;
  public geoInfo: any;
  public showTime: boolean = false;
  public today: NgbDateStruct;
  public areasIntersected = new Array();
  public contactConfig: any;
  private geojsonSubscription$: Subscription;

  constructor(private _ms: MapService, private _dfs: DataFormService, public fs: ContactFormService,
  private _commonService: CommonService, private modalService: NgbModal, private _dateFormater: NgbDateParserFormatter) {  }

  ngOnInit() {
    this.contactConfig = ContactConfig;

    // get all nomenclatures definitions

    // this._dfs.getNomenclatures(100, 14, 7, 13, 8, 106, 101, 15, 10, 9, 6, 21)
    //   .subscribe(data )

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
          });
      });

    // date max autocomplete
      (this.releveForm.controls.properties as FormGroup).controls.date_min.valueChanges
        .subscribe(value => {
          if (this.releveForm.value.properties.date_max === null ) {
            this.releveForm.controls.properties.patchValue({date_max: value});
          }
        });
      // set today for the datepicker limit
      const today = new Date();
      this.today = { year: today.getFullYear(), month: today.getMonth() + 1, day: today.getDate() };

    // check if dateMax is not < dateMin
    (this.releveForm.controls.properties as FormGroup).controls.date_max.valueChanges
      .debounceTime(500)
      .subscribe(value => {
        this.checkDate();
      });

    (this.releveForm.controls.properties as FormGroup).controls.date_min.valueChanges
      .debounceTime(500)
      .subscribe(value => {
        this.checkDate();
      });






    // check if hour max is not inf to hour max
    (this.releveForm.controls.properties as FormGroup).controls.hour_max.valueChanges
      // wait for the end of the input
      .debounceTime(500)
      .filter(value => (this.releveForm.controls.properties as FormGroup).controls.hour_max.valid)
      .subscribe(value => {
        this.checkHours();
      });
      // check if hour max is not inf to hour max
      (this.releveForm.controls.properties as FormGroup).controls.hour_min.valueChanges
      .filter(value => (this.releveForm.controls.properties as FormGroup).controls.hour_min.valid)
      .debounceTime(500)
      .subscribe(value => {
        this.checkHours();
      });
  } // END INIT

  checkHours() {
    let hourMin = this.releveForm.value.properties.hour_min;
    let hourMax = this.releveForm.value.properties.hour_max;
    // if hour min et pas hour max => set error
    if (hourMin && hourMax) {
      hourMin = hourMin.split(':').map(h => parseInt(h));
      hourMax = hourMax.split(':').map(h => parseInt(h));
      const dateMin = new Date(this._dateFormater.format(this.fs.releveForm.value.properties.date_min));
      const dateMax = new Date(this._dateFormater.format(this.fs.releveForm.value.properties.date_max));
      if (dateMin && dateMax) {
        dateMin.setHours(hourMin[0], hourMin[1]);
        dateMax.setHours(hourMax[0], hourMax[1]);
        console.log(dateMin > dateMax);
      }

      if (dateMin > dateMax) {
        (this.releveForm.controls.properties as FormGroup).controls.hour_max.setErrors([Validators.required]);
        this._commonService.translateToaster('error', 'Releve.HourMaxError');
      } else {
        (this.releveForm.controls.properties as FormGroup).controls.hour_max.updateValueAndValidity();

      }
    }
  }

  checkDate() {
    const dateMin = this.releveForm.value.properties.date_min;
    const dateMax = this.releveForm.value.properties.date_max;
    if (dateMin && dateMax) {
      this.dateMin = new Date(dateMin.year, dateMin.month, dateMin.day);
      this.dateMax = new Date(dateMax.year, dateMax.month, dateMax.day);
      if (this.dateMax < this.dateMin) {
        (this.releveForm.controls.properties as FormGroup).controls.date_max.setErrors([Validators.required]);
        this._commonService.translateToaster('error', 'Releve.DateMaxError');
      }
      // check hours
      this.checkHours();
    }
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
