import { Injectable } from "@angular/core";
import {
  FormBuilder,
  FormGroup,
  Validators
} from "@angular/forms";
import { forkJoin } from "rxjs";
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
    private coreFormService: FormService,
    private dataFormService: DataFormService,
    private occtaxFormService: OcctaxFormService,
    private occtaxFormMapService: OcctaxFormMapService
  ) {
    this.currentHourMax = null;

    this.initForm();
    this.setObservables();
  }

  initForm(): void {
    //FORM
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

    // VALIDATORS
    this.form.setValidators([
      this.coreFormService.dateValidator(
        this.form.get("date_min"),
        this.form.get("date_max")
      ),
      this.coreFormService.hourAndDateValidator(
        this.form.get("date_min"),
        this.form.get("date_max"),
        this.form.get("hour_min"),
        this.form.get("hour_max")
      ),
      this.coreFormService.altitudeValidator(
        this.form.get("altitude_min"),
        this.form.get("altitude_max")
      )
    ]);

  }

  private setObservables() {

    // Mise en forme de la date à partir des données de l'API
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

    // AUTOCOMPLETE DATE ON EDIT
    // Observation de l'état d'édition pour activer l'autocomplétion de la date ou non.
    this.occtaxFormService.editionMode
      .pipe(filter((editionMode: boolean) => !editionMode)) //si on est en mode creation uniquement
      .subscribe(editionMode => {
        this.coreFormService.autoCompleteDate(
          this.form as FormGroup,
          'date_min',
          'date_max'
        );
      });

    // AUTOCORRECTION de hour
    // si le champ est une chaine vide ('') on reset la valeur null
    this.form.get('hour_min')
                  .valueChanges
                  .pipe(
                    filter(hour => hour && hour.length == 0)
                  )
                  .subscribe(hour => {
                    this.form.get('hour_min').reset();
                  });

    this.form.get('hour_max')
                  .valueChanges
                  .pipe(
                    filter(hour => hour && hour.length == 0)
                  )
                  .subscribe(hour => {
                    this.form.get('hour_max').reset();
                  });

    // AUTOCOMPLETE DE hour_max par hour_min UNIQUEMENT SI editionMode = FAUX
    this.form.get('hour_min')
                  .valueChanges
                  .pipe(
                    filter(hour => !this.occtaxFormService.editionMode.getValue() && hour != null)
                  ).subscribe(hour => {
                    if (
                      // autcomplete only if hour max is empty or invalid
                      (this.form.get('hour_max').invalid ||
                      this.form.get('hour_max').value == null)
                    ) {
                        this.form.get('hour_max').setValue(hour);
                    }
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
