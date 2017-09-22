import { Component, Input, OnInit, OnDestroy } from '@angular/core';
import { FormGroup, FormArray, FormControl } from '@angular/forms';
import { Subscription } from 'rxjs/Subscription';
import { MapService } from '../../map/map.service';
import { DataFormService } from '../data-form.service';
import { FormService } from '../form.service';
import {ViewEncapsulation} from '@angular/core';
import {NgbDateStruct} from '@ng-bootstrap/ng-bootstrap';


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
  public municipalities: string;
  public showTime: boolean = false;
  public today: NgbDateStruct;
  private geojsonSubscription$: Subscription;

  constructor(private _ms: MapService, private _dfs: DataFormService, public fs: FormService) {  }

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
              municipalities : res.municipality.map(m =>  m.source_code)
            });
            this.fs.municipalities = res.municipality.map(m => m.area_name).join();
          });
      });

    // date max autocomplete
    (this.releveForm.controls.properties as FormGroup).controls.date_min.valueChanges
      .subscribe(value => {
        this.releveForm.controls.properties.patchValue({date_max: value});
      });
    // set today
    const today = new Date();
    this.today = { year: today.getFullYear(), month: today.getMonth() + 1, day: today.getDate() };

  }

  toggleDate() {
    this.showTime = !this.showTime;
  }

  ngOnDestroy() {
    this.geojsonSubscription$.unsubscribe();
  }
}
