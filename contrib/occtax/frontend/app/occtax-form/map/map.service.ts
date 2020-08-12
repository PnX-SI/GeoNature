import { Injectable } from "@angular/core";
import { FormControl, Validators } from "@angular/forms";
import { isEqual } from "lodash";
import { BehaviorSubject, Observable, of } from "rxjs";
import { GeoJSON } from "leaflet";
import { filter, map, switchMap } from "rxjs/operators";
import { OcctaxFormService } from "../occtax-form.service";
import { OcctaxFormParamService } from "../form-param/form-param.service";

@Injectable()
export class OcctaxFormMapService {
  private _geometry: FormControl;
  public geojson: BehaviorSubject<GeoJSON> = new BehaviorSubject(null);

  get geometry() {
    return this._geometry;
  }
  set geometry(geojson: GeoJSON) {
    if (!isEqual(geojson.geometry, this._geometry.value)) {
      this._geometry.setValue(geojson.geometry);
      this._geometry.markAsDirty();
    }
  }

  constructor(
    private occtaxFormService: OcctaxFormService,
    private occtaxParamS: OcctaxFormParamService
  ) {
    this.initForm();
    this.setObservables();
  }

  initForm(): void {
    this._geometry = new FormControl(null, Validators.required);
  }

  /**
   * Initialise les observables pour la mise en place des actions automatiques
   **/
  private setObservables() {
    //patch la geometrie par la valeur par defaut si creation et si existante
    this.occtaxFormService.editionMode
      .pipe(
        switchMap((editionMode: boolean) => {
          //Le switch permet, selon si édition ou creation, de récuperer les valeur par defaut ou celle de l'API
          return editionMode
            ? this.releveGeojsonValue
            : of(this.occtaxParamS.get("geometry"));
        })
      )
      .subscribe((geometry) => this._geometry.setValue(geometry));

    //active la saisie si la geometry est valide
    this._geometry.valueChanges
      .pipe(
        map((geometry) =>
          this._geometry.valid ? { geometry: geometry } : null
        )
      )
      .subscribe((geojson) => {
        this.geojson.next(geojson);
      });
  }

  private get releveGeojsonValue(): Observable<any> {
    return this.occtaxFormService.occtaxData.pipe(
      filter((data) => data && data.releve.geometry),
      map((data) => data.releve.geometry)
    );
  }

  reset() {
    this._geometry.setValue(null);
    this._geometry.updateValueAndValidity();
  }
}
