import { Injectable } from "@angular/core";
import {
  FormBuilder,
  FormGroup,
  Validators
} from "@angular/forms";
import { Router, ActivatedRoute } from "@angular/router";
import { Observable, Subscription } from "rxjs";
import { filter, map, switchMap, tap } from "rxjs/operators";
import { NgbDateParserFormatter } from "@ng-bootstrap/ng-bootstrap";
import { GeoJSON } from "leaflet";
import { AppConfig } from "@geonature_config/app.config";
import { ModuleConfig } from "../../module.config";
import { CommonService } from "@geonature_common/service/common.service";
import { FormService } from "@geonature_common/form/form.service";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { OcctaxFormService } from '../occtax-form.service';
import { OcctaxFormMapService } from '../map/map.service';
import { OcctaxDataService } from '../../services/occtax-data.service';

@Injectable()
export class OcctaxFormReleveService {
  public userReleveRigth: any;
  public $_autocompleteDate: Subscription = new Subscription();

  public propertiesForm: FormGroup;
  public releve: any;
  public geojson: GeoJSON;
  public releveForm: FormGroup;

  public waiting: boolean = false;
  public route: ActivatedRoute;

  constructor(
    private router: Router,
    private fb: FormBuilder,
    private _commonService: CommonService,
    private dateParser: NgbDateParserFormatter,
    private coreFormService: FormService,
    private dataFormService: DataFormService,
    private occtaxFormService: OcctaxFormService,
    private occtaxFormMapService: OcctaxFormMapService,
    private occtaxDataService: OcctaxDataService
  ) {
    this.initPropertiesForm();
    this.setObservables();

    this.releveForm = this.fb.group({
      geometry: this.occtaxFormMapService.geometry,
      properties: this.propertiesForm
    });
  }

  private get initialValues() {
    return {
      id_digitiser: this.occtaxFormService.currentUser.id_role,
      meta_device_entry: "web",
      observers: [this.occtaxFormService.currentUser]
    };
  }

  initPropertiesForm(): void {
    //FORM
    this.propertiesForm = this.fb.group({
      // id_releve_occtax: null,
      id_dataset: [null, Validators.required],
      id_digitiser: null,
      date_min: [null, Validators.required],
      date_max: [null, Validators.required],
      hour_min: [null, Validators.pattern("^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$")],
      hour_max: [null, Validators.pattern("^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$")],
      altitude_min: null,
      altitude_max: null,
      meta_device_entry: null,
      comment: null,
      id_nomenclature_obs_technique: [null, Validators.required],
      observers: [null, (!ModuleConfig.observers_txt ? Validators.required : null)],
      observers_txt: [ null, (ModuleConfig.observers_txt ? Validators.required : null)],
      id_nomenclature_grp_typ: null
    });

    this.propertiesForm.patchValue(this.initialValues);

    // VALIDATORS
    this.propertiesForm.setValidators([
      this.coreFormService.dateValidator(
        this.propertiesForm.get("date_min"),
        this.propertiesForm.get("date_max")
      ),
      this.coreFormService.hourAndDateValidator(
        this.propertiesForm.get("date_min"),
        this.propertiesForm.get("date_max"),
        this.propertiesForm.get("hour_min"),
        this.propertiesForm.get("hour_max")
      ),
      this.coreFormService.altitudeValidator(
        this.propertiesForm.get("altitude_min"),
        this.propertiesForm.get("altitude_max")
      )
    ]);

    //on desactive le form, il sera réactivé si la geom est ok
    this.propertiesForm.disable();
  }


  /**
  * Initialise les observables pour la mise en place des actions automatiques
  **/
  private setObservables() {

    //patch le form par les valeurs par defaut si creation
    this.occtaxFormService.editionMode
      .pipe(
        tap((editionMode: boolean)=>{
          // gestion de l'autocomplétion de la date ou non.
          this.$_autocompleteDate.unsubscribe();
          if (!editionMode) {
            this.$_autocompleteDate = this.coreFormService.autoCompleteDate(
                      this.propertiesForm as FormGroup,
                      'date_min',
                      'date_max'
                    );
          } 
        }),
        switchMap((editionMode: boolean) => {
          //Le switch permet, selon si édition ou creation, de récuperer les valeur par defaut ou celle de l'API
          return editionMode ? this.releveValues : this.defaultValues;
        })
      ).subscribe(values=>this.propertiesForm.patchValue(values))//filter((editionMode: boolean) => !editionMode))
    
    //Observation de la geometry pour récupere les info d'altitudes
    this.occtaxFormMapService.geojson
                  .pipe(
                    filter(geojson=>geojson !== null),
                    tap((geojson)=>{
                      //geom valide
                      if (!this.occtaxFormService.editionMode.getValue()) {
                        //recup des info d'altitude uniquement en mode creation
                        this.getAltitude(geojson)
                      }
                      this.propertiesForm.enable(); //active le form
                    })
                  )
                  .subscribe(geojson=>this.geojson = geojson);


    // AUTOCORRECTION de hour
    // si le champ est une chaine vide ('') on reset la valeur null
    this.propertiesForm.get('hour_min')
                  .valueChanges
                  .pipe(
                    filter(hour => hour && hour.length == 0)
                  )
                  .subscribe(hour => {
                    this.propertiesForm.get('hour_min').reset();
                  });

    this.propertiesForm.get('hour_max')
                  .valueChanges
                  .pipe(
                    filter(hour => hour && hour.length == 0)
                  )
                  .subscribe(hour => {
                    this.propertiesForm.get('hour_max').reset();
                  });

    // AUTOCOMPLETE DE hour_max par hour_min UNIQUEMENT SI editionMode = FAUX
    this.propertiesForm.get('hour_min')
                  .valueChanges
                  .pipe(
                    filter(hour => !this.occtaxFormService.editionMode.getValue() && hour != null)
                  ).subscribe(hour => {
                    if (
                      // autcomplete only if hour max is empty or invalid
                      (this.propertiesForm.get('hour_max').invalid ||
                      this.propertiesForm.get('hour_max').value == null)
                    ) {
                        this.propertiesForm.get('hour_max').setValue(hour);
                    }
                  });
  }

  private get releveValues(): Observable<any> {
    return this.occtaxFormService.occtaxData
                    .pipe(
                      filter(data=> data && data.releve.properties),
                      map(data=>{
                        let releve = data.releve.properties;
                        releve.date_min = this.formatDate(releve.date_min);
                        releve.date_max = this.formatDate(releve.date_max);
                        return releve;
                      })
                    );
  }

  private get defaultValues(): Observable<any> {
    return this.occtaxFormService.getDefaultValues(this.occtaxFormService.currentUser.id_organisme)
                    .pipe(
                      map(data=> {
                        return {
                          id_nomenclature_grp_typ: data["TYP_GRP"],
                          id_nomenclature_obs_technique: data["TECHNIQUE_OBS"]
                        };
                      })
                    );
  }

  private getAltitude(geojson) {
    // get to geo info from API
    this.dataFormService.getGeoInfo(geojson).subscribe(res => {
      this.propertiesForm.patchValue({
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

  get releveFormValue() {
    let value = this.releveForm.value;
    value.properties.date_min = this.dateParser.format(
      value.properties.date_min
    );
    value.properties.date_max = this.dateParser.format(
      value.properties.date_max
    );
    value.properties.observers = value.properties.observers.map(observer=>observer.id_role);
    return value;
  }

  submitReleve() {  
    this.waiting = true;

    if (this.occtaxFormService.id_releve_occtax.getValue()) {
      //update
      this.occtaxDataService
                  .updateReleve(this.occtaxFormService.id_releve_occtax.getValue(), this.releveFormValue)
                  .pipe(
                    tap(()=>this.waiting = false)
                  )
                  .subscribe(
                    (data:any) => {
                      this._commonService.translateToaster(
                        "info",
                        "Releve.Infos.ReleveModified"
                      );
                      this.occtaxFormService.replaceReleveData(data);
                      this.releveForm.markAsPristine()
                    },
                    err => {
                      this.waiting = false;
                      this._commonService.translateToaster(
                        "error",
                        "ErrorMessage"
                      );
                    }
                  );
    } else {
      //create
      this.occtaxDataService
                  .createReleve(this.releveFormValue)
                  .pipe(
                    tap(()=>this.waiting = false)
                  )
                  .subscribe(
                    (data:any) => {
                      this._commonService.translateToaster(
                        "info",
                        "Releve.Infos.ReleveAdded"
                      );
                      this.router.navigate([data.id, 'taxons'], {relativeTo: this.route})
                    },
                    err => {
                      this.waiting = false;
                      this._commonService.translateToaster(
                        "error",
                        "ErrorMessage"
                      );
                    }
                  );
    }
  }

  reset() {
    this.propertiesForm.reset(this.initialValues);
  }
}
