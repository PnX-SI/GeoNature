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
  private _commonService: CommonService, private modalService: NgbModal) {  }

  ngOnInit() {
    this.contactConfig = ContactConfig;

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
        this.releveForm.controls.properties.patchValue({date_max: value});
      });
    // set today for the datepicker limit
    const today = new Date();
    this.today = { year: today.getFullYear(), month: today.getMonth() + 1, day: today.getDate() };

    // check if dateMax is not < dateMin
    (this.releveForm.controls.properties as FormGroup).controls.date_max.valueChanges
    .debounceTime(500)
    .subscribe(value => {
      const dateMin = this.releveForm.value.properties.date_min;
      if (dateMin) {
        this.dateMin = new Date(dateMin.year, dateMin.month, dateMin.day);
         this.dateMax = new Date(value.year, value.month, value.day);
        if (this.dateMax < this.dateMin) {
          (this.releveForm.controls.properties as FormGroup).controls.date_max.setErrors([Validators.required]);
          this._commonService.translateToaster('error', 'Releve.DateMaxError');
        }
      }
    });

    // check if hour max is not inf to hour max
    (this.releveForm.controls.properties as FormGroup).controls.hour_max.valueChanges
      .debounceTime(2000)
      .subscribe(value => {
        let hourMin = this.releveForm.value.properties.hour_min;
         hourMin = hourMin.split(':').map(h => parseInt(h));
        const hourMax = value.split(':').map(h => parseInt(h));
        this.dateMin.setHours(hourMin[0], hourMin[1]);
        this.dateMax.setHours(hourMax[0], hourMax[1]);
        console.log(this.dateMin > this.dateMax);
        
        if(this.dateMin > this.dateMax) {
          (this.releveForm.controls.properties as FormGroup).controls.hour_max.setErrors([Validators.required]);
        }
        
      })
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
