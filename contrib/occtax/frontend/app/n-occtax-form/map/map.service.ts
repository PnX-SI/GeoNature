import { Injectable } from "@angular/core";
import {
  FormBuilder,
  FormControl,
  Validators
} from "@angular/forms";
import { GeoJSON } from "leaflet";
import { filter, map } from "rxjs/operators";
import { HttpClient, HttpParams } from "@angular/common/http";
import { OcctaxFormService } from '../occtax-form.service';

@Injectable()
export class OcctaxFormMapService {
 
  public geometry: FormControl;

  get geojson() { 
    return this.geometry.value; 
  }
  set geojson(geojson) { 
    if (JSON.stringify(geojson.geometry) !== JSON.stringify(this.geometry.value) ) {
      this.geometry.setValue(geojson.geometry); 
    }
  }

  constructor(
    private _fb: FormBuilder,
    private _http: HttpClient,
    private occtaxFormService: OcctaxFormService
  ) {
    this.geometry = new FormControl(null, Validators.required);

    //Observe les données, si édition patch le formulaire par la valeur du relevé
    this.occtaxFormService.occtaxData
            .pipe(
              filter(data=> data && data.releve.geometry),
              map(data=>data.releve.geometry)
            )
            .subscribe(geometry=>this.geometry.setValue(geometry));

    //active la saisie si la geometry est valide
    this.geometry.valueChanges
                .subscribe(geojson => {
                  this.occtaxFormService.disabled = this.geometry.invalid;
                });
  } 

}
