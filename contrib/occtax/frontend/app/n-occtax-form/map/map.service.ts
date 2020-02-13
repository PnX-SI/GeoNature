import { Injectable } from "@angular/core";
import {
  FormBuilder,
  FormGroup,
  Validators
} from "@angular/forms";
import { GeoJSON } from "leaflet";
import { BehaviorSubject } from "rxjs/BehaviorSubject";
import { HttpClient, HttpParams } from "@angular/common/http";

@Injectable()
export class OcctaxFormMapService {

  public markerCoordinates: Array<any>;
  public geojsonCoordinates: GeoJSON;
  
  private form: FormGroup;
  private _geojson: BehaviorSubject<GeoJSON> = new BehaviorSubject(null);
  get geojson(): BehaviorSubject<GeoJSON> { return this._geojson; }
  set geojson(geojson: GeoJSON) { this._geojson.next(geojson); }

  constructor(
    private _fb: FormBuilder,
    private _http: HttpClient,
  ) {
    this.initForm();
  } // end constructor

  initForm(): void {
    this.form = this._fb.group({
      geometry: [null, Validators.required]
    });

    this.geojson.subscribe(geojson=> {
                  this.form.get('geometry').value = geojson;

                  // get to geo info from API
                  // this._dfs.getGeoInfo(geojson).subscribe(res => {
                  //   this.releveForm.controls.properties.patchValue({
                  //     altitude_min: res.altitude.altitude_min,
                  //     altitude_max: res.altitude.altitude_max
                  //   });
                  // });

                  // this._dfs.getFormatedGeoIntersection(geojson).subscribe(res => {
                  //   this.areasIntersected = res;
                  // });
                });
  }
}
