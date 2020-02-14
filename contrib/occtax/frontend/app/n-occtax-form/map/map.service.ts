import { Injectable } from "@angular/core";
import {
  FormBuilder,
  FormControl,
  Validators
} from "@angular/forms";
import { BehaviorSubject } from "rxjs";
import { GeoJSON } from "leaflet";
import { filter, map } from "rxjs/operators";
import { HttpClient, HttpParams } from "@angular/common/http";
import { OcctaxFormService } from '../occtax-form.service';

@Injectable()
export class OcctaxFormMapService {
 
  private _geometry: FormControl;
  public geojson: BehaviorSubject<GeoJSON> = new BehaviorSubject(null);

  get geometry(): FormControl { return this._geometry; }
  set geometry(geojson) { 
    if (JSON.stringify(geojson.geometry) !== JSON.stringify(this.geometry.value) ) {
      this.geometry.setValue(geojson.geometry); 
    }
  }

  constructor(
    private _fb: FormBuilder,
    private _http: HttpClient,
    private occtaxFormService: OcctaxFormService
  ) {
    this._geometry = new FormControl(null, Validators.required);

    //Observe les données, si édition patch le formulaire par la valeur du relevé
    this.occtaxFormService.occtaxData
            .pipe(
              filter(data=> data && data.releve.geometry),
              map(data=>data.releve.geometry)
            )
            .subscribe(geometry=>this.geometry.setValue(geometry));

    //active la saisie si la geometry est valide
    this.geometry.valueChanges
                .subscribe(geometry => {
                  this.occtaxFormService.disabled = this.geometry.invalid;
                  this.geojson.next({geometry: geometry});
                });
  } 

}
