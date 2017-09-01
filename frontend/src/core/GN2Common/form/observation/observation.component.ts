import { Component, Input, OnInit, OnDestroy } from '@angular/core';
import { FormGroup, FormArray } from '@angular/forms';
import { Subscription } from 'rxjs/Subscription';
import { MapService } from '../../map/map.service';
import { DataFormService } from '../data-form.service';

@Component({
  selector: 'pnx-observation',
  templateUrl: 'observation.component.html'
})

export class ObservationComponent implements OnInit, OnDestroy {
  @Input() releveForm: FormGroup;
  public geojson: any;
  public dataSets: any;
  public geoInfo: any;
  private geojsonSubscription: Subscription;
  
  constructor(private _ms:MapService, private _dfs: DataFormService) {  }

  ngOnInit() {
    //load datasets
    this._dfs.getDatasets()
    .subscribe(res => this.dataSets = res);
    // provisoire:
    this.dataSets = [1, 2, 3];

    // subscription to the geojson observable
    this.geojsonSubscription = this._ms.gettingGeojson$
    .subscribe(geojson => {
      this.releveForm.value.geometry = geojson.geometry;
      this.geojson = geojson;
      // subscribe to geo info
      // this._dfs.getGeoInfo(geojson)
      //   .subscribe(res => this.geoInfo = res);
    });
  }
  
  ngOnDestroy(){
    this.geojsonSubscription.unsubscribe();
  }
}