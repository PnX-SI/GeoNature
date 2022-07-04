import { Injectable } from "@angular/core";
import { FormControl, Validators } from "@angular/forms";
import { isEqual } from "lodash";
import { BehaviorSubject, Observable, of } from "rxjs";
import { filter, map, switchMap } from "rxjs/operators";
import { OcctaxFormService } from "../occtax-form.service";
import { OcctaxFormParamService } from "../form-param/form-param.service";

@Injectable()
export class OcctaxFormMapService {
  private _geometry: FormControl;
  public geojson: BehaviorSubject<any> = new BehaviorSubject(null);
  public markerCoordinates;
  public leafletDrawGeoJson;

  get geometry() {
    return this._geometry;
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

  setGeometryFromMap(geojson) {
    this.manageGeometryChange(geojson);
  }

  setGeometryFromAPI(geojson) {
    this.manageGeometryChange(geojson);
    if (geojson.type == "Point") {
      this.markerCoordinates = geojson.coordinates;
    } else {
      this.leafletDrawGeoJson = geojson;
    }
  }

  manageGeometryChange(geojson) {
    if (!isEqual(geojson.geometry, this._geometry.value)) {
      this._geometry.setValue(geojson.geometry);
      this._geometry.markAsDirty();
      this.occtaxFormService.disabled = false;
    }
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
        }),
        filter((geojson) => geojson != null)
      )
      .subscribe((geometry) => {
        this.setGeometryFromAPI(geometry);
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
