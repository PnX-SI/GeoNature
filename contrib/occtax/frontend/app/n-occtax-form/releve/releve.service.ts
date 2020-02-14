import { Injectable } from "@angular/core";
import {
  FormBuilder,
  FormGroup,
  Validators
} from "@angular/forms";
import { filter, map } from "rxjs/operators";
import { GeoJSON } from "leaflet";
import { AppConfig } from "@geonature_config/app.config";
import { ModuleConfig } from "../../module.config";
import { FormService } from "@geonature_common/form/form.service";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { OcctaxFormService } from '../occtax-form.service';
import { OcctaxFormMapService } from '../map/map.service';

@Injectable()
export class OcctaxFormReleveService {
  public defaultValues: any;
  public defaultValuesLoaded = false;
  public userReleveRigth: any;
  public currentHourMax: string;
  public currentReleve: any;

  public form: FormGroup;
  public releve: any;
  public geojson: GeoJSON;

  constructor(
    private _fb: FormBuilder,
    private _formService: FormService,
    private dataFormService: DataFormService,
    private occtaxFormService: OcctaxFormService,
    private occtaxFormMapService: OcctaxFormMapService
  ) {
    this.currentHourMax = null;

    this.initForm();
    this.setObservables();
  }

  initForm(): FormGroup {

    this.form = this._fb.group({
      id_releve_occtax: null,
      id_dataset: [null, Validators.required],
      id_digitiser: this.occtaxFormService.currentUser.id_role, //initialisation par l'user en cours
      date_min: [null, Validators.required],
      date_max: [null, Validators.required],
      hour_min: [
        null,
        Validators.pattern(
          "^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$"
        )
      ],
      hour_max: [
        null,
        Validators.pattern(
          "^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$"
        )
      ],
      altitude_min: null,
      altitude_max: null,
      meta_device_entry: "web",
      comment: null,
      id_nomenclature_obs_technique: [null, Validators.required],
      observers: [
        [this.occtaxFormService.currentUser], //initialisation par l'user en cours
        !ModuleConfig.observers_txt ? Validators.required : null
      ],
      observers_txt: [
        null,
        ModuleConfig.observers_txt ? Validators.required : null
      ],
      id_nomenclature_grp_typ: null,
      t_occurrences_occtax: [new Array()]
    });

    // validtors on date and hours
    this.form.setValidators([
      this._formService.dateValidator(
        this.form.get("date_min"),
        this.form.get("date_max")
      ),
      this._formService.hourAndDateValidator(
        this.form.get("date_min"),
        this.form.get("date_max"),
        this.form.get("hour_min"),
        this.form.get("hour_max")
      ),
      this._formService.altitudeValidator(
        this.form.get("altitude_min"),
        this.form.get("altitude_max")
      )
    ]);
  }

  private setObservables() {
    this.occtaxFormService.occtaxData
            .pipe(
              filter(data=> data && data.releve.properties),
              map(data=>{
                let releve = data.releve.properties;
                releve.date_min = this.formatDate(releve.date_min);
                releve.date_max = this.formatDate(releve.date_max);
                return releve;
              })
            )
            .subscribe(releve=>this.form.patchValue(releve));

    //Observation de la geometry pour récupere les info d'altitudes
    this.occtaxFormMapService.geojson
                  .pipe(filter(geojson=>geojson !== null))
                  .subscribe(geojson=>{
                      this.geojson = geojson;
                      // get to geo info from API
                      this.getAltitude();
                  });
  }

  private getAltitude() {
    // get to geo info from API
    this.dataFormService.getGeoInfo(this.geojson).subscribe(res => {
      this.form.patchValue({
        altitude_min: res.altitude.altitude_min,
        altitude_max: res.altitude.altitude_max
      });
    });
  }

  private formatDate(strDate) {
    const date = new Date(strDate);
    return {
      year: date.getFullYear(),
      month: date.getMonth() + 1,
      day: date.getDate()
    };
  }

  reset() {
    this.initForm();
  }
}
