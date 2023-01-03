import { Injectable, ChangeDetectorRef } from "@angular/core";
import {
  FormBuilder,
  FormGroup,
  FormControl,
  Validators,
} from "@angular/forms";
import { Router, ActivatedRoute } from "@angular/router";
import { Observable, Subscription, of, combineLatest, forkJoin } from "rxjs";
import {
  filter,
  map,
  switchMap,
  tap,
  skip,
  concatMap,
  distinctUntilChanged,
  pairwise,
} from "rxjs/operators";
import { NgbDateParserFormatter } from "@ng-bootstrap/ng-bootstrap";
import { ModuleConfig } from "../../module.config";
import { CommonService } from "@geonature_common/service/common.service";
import { FormService } from "@geonature_common/form/form.service";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { OcctaxFormService } from "../occtax-form.service";
import { OcctaxFormMapService } from "../map/occtax-map.service";
import { OcctaxDataService } from "../../services/occtax-data.service";
import { OcctaxFormParamService } from "../form-param/form-param.service";
import { DatasetStoreService } from "@geonature_common/form/datasets/dataset.service";
import { MapService } from "@geonature_common/map/map.service";
import { ModuleService } from "@geonature/services/module.service";

@Injectable()
export class OcctaxFormReleveService {
  public userReleveRigth: any;

  public propertiesForm: FormGroup;
  public habitatForm = new FormControl();
  public releve: any;
  public releveForm: FormGroup;
  //custom additional fields
  public additionalFieldsForm: Array<any> = [];

  public showTime: boolean = false; //gestion de l'affichage des infos complémentaires de temps
  public waiting: boolean = false;
  public route: ActivatedRoute;

  public currentIdDataset: any;

  public datasetId: number = null;
  public previousReleve = null;

  constructor(
    private router: Router,
    private fb: FormBuilder,
    private _commonService: CommonService,
    private dateParser: NgbDateParserFormatter,
    private coreFormService: FormService,
    private dataFormService: DataFormService,
    private occtaxFormService: OcctaxFormService,
    private occtaxFormMapService: OcctaxFormMapService,
    private occtaxDataService: OcctaxDataService,
    private occtaxParamS: OcctaxFormParamService,
    private _datasetStoreService: DatasetStoreService,
    private _cd: ChangeDetectorRef,
    private _mapService: MapService,
    public moduleService: ModuleService
  ) {
    this.initPropertiesForm();
    this.setObservables();
    this.releveForm = this.fb.group({
      geometry: this.occtaxFormMapService.geometry,
      properties: this.propertiesForm,
    });
  }

  private get initialValues() {
    return {
      id_digitiser: this.occtaxFormService.currentUser.id_role,
      meta_device_entry: "web",
    };
  }

  initPropertiesForm(): void {
    //FORM
    this.propertiesForm = this.fb.group({
      id_dataset: [null, Validators.required],
      id_digitiser: null,
      id_module: this.moduleService.currentModule.id_module,
      date_min: [null, Validators.required],
      date_max: [null, Validators.required],
      hour_min: [
        null,
        Validators.pattern(
          "^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$"
        ),
      ],
      hour_max: [
        null,
        Validators.pattern(
          "^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$"
        ),
      ],
      altitude_min: null,
      altitude_max: null,
      depth_min: null,
      depth_max: null,
      place_name: null,
      meta_device_entry: null,
      comment: null,
      cd_hab: null,
      id_nomenclature_tech_collect_campanule: null,
      observers: [
        null,
        !ModuleConfig.observers_txt ? Validators.required : null,
      ],
      observers_txt: [
        null,
        ModuleConfig.observers_txt ? Validators.required : null,
      ],
      id_nomenclature_grp_typ: null,
      grp_method: null,
      id_nomenclature_geo_object_nature: null,
      precision: null,
      additional_fields: this.fb.group({}),
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
      this.coreFormService.minMaxValidator(
        this.propertiesForm.get("altitude_min"),
        this.propertiesForm.get("altitude_max"),
        "invalidAlt"
      ),
      this.coreFormService.minMaxValidator(
        this.propertiesForm.get("depth_min"),
        this.propertiesForm.get("depth_max"),
        "invalidDepth"
      ),
    ]);
  }

  onDatasetChanged(idDataset) {
    // const currentDataset = this._datasetStoreService.datasets.find(d => d.id_dataset == idDataset);
    // if(currentDataset && currentDataset.id_taxa_list) {
    //   this.occtaxFormService.idTaxonList = currentDataset.id_taxa_list;
    // } else {
    //   this.occtaxFormService.idTaxonList = ModuleConfig.id_taxon_list
    // }
    this.occtaxFormService
      .getAdditionnalFields(["OCCTAX_RELEVE"], idDataset)
      .pipe(
        map((datasetAdditionalFields) => {
          return (
            []
              .concat(
                this.additionalFieldsForm.filter(
                  (elem) => !elem.datasets.length
                ),
                datasetAdditionalFields
              )
              //set form field value
              .map((elem) => {
                const releve_add_fields =
                  this.propertiesForm.get("additional_fields").value;
                if (releve_add_fields[elem.attribut_name] !== undefined) {
                  elem.value = releve_add_fields[elem.attribut_name];
                }
                return elem;
              })
          );
        })
      )
      .subscribe(
        (additionalFieldsForm) =>
          (this.additionalFieldsForm = additionalFieldsForm)
      );
  }

  /**
   * Initialise les observables pour la mise en place des actions automatiques
   **/
  private setObservables() {
    //patch le form par les valeurs par defaut si creation
    this.occtaxFormService.editionMode
      .pipe(
        skip(1), // skip initilization value (false)
        //initialisation
        tap(() => {
          this.additionalFieldsForm = [];
        }),
        switchMap((editionMode: boolean) => {
          //Le switch permet, selon si édition ou creation, de récuperer les valeur par defaut ou celle de l'API
          return editionMode ? this.releveValues : this.defaultValues;
        }),
        //display showTime management
        tap(
          (values) =>
            (this.showTime = !(
              JSON.stringify(values.date_min) ===
              JSON.stringify(values.date_max)
            ))
        ),
        //get additional fidlds from releve
        switchMap((releve) => {
          let additionnalFieldsObservable: Observable<any>;
          //if releve.id_dataset is empty, get GlobalAdditionnalFields only
          if (releve.id_dataset === null) {
            additionnalFieldsObservable =
              this.occtaxFormService.getAdditionnalFields(["OCCTAX_RELEVE"]);
          } else {
            //set 2 request for get global & dataset additional field together
            additionnalFieldsObservable = forkJoin(
              //globalAdditionnalFields
              this.occtaxFormService.getAdditionnalFields(["OCCTAX_RELEVE"]),
              //datasetAdditionnalFields
              this.occtaxFormService.getAdditionnalFields(
                ["OCCTAX_RELEVE"],
                releve.id_dataset
              )
            ).pipe(
              //concatenation for restitute only one additional fields array
              map(([globalFields, datasetFields]) =>
                [].concat(globalFields, datasetFields)
              )
            );
          }
          return forkJoin(of(releve), additionnalFieldsObservable);
        }),
        map(([releve, additional_fields]) => {
          additional_fields.forEach((field) => {
            //Formattage des dates
            if (field.type_widget == "date") {
              //On peut passer plusieurs fois ici, donc on vérifie que la date n'est pas déja formattée
              if (
                typeof releve.additional_fields[field.attribut_name] !==
                "object"
              ) {
                releve.additional_fields[field.attribut_name] =
                  this.occtaxFormService.formatDate(
                    releve.additional_fields[field.attribut_name]
                  );
              }
            }

            //set value of field (eq patchValue)
            if (releve.additional_fields[field.attribut_name] !== undefined) {
              field.value = releve.additional_fields[field.attribut_name];
            }
          });

          return [releve, additional_fields];
        }),
        //set the additional Fields Form
        tap(
          ([releve, additional_fields]) =>
            (this.additionalFieldsForm = additional_fields)
        ),
        //map for return releve data only
        map(([releve, additional_fields]) => releve)
      )
      .subscribe((releve_data) => {
        this.propertiesForm.patchValue(releve_data);
      });

    //Observation de la geometry pour récupere les info d'altitudes
    // cet evenement est émit uniquement lors de changement sur la carte
    // pas à partir d'un patch de l'API
    this._mapService.gettingGeojson$
      .pipe(
        distinctUntilChanged(),
        filter((geojson) => geojson !== null),
        tap((geojson) => {
          this.occtaxFormService.disabled = false;
          this.occtaxFormMapService.setGeometryFromMap(geojson);
        }),
        switchMap((geojson) => this.dataFormService.getAltitudes(geojson))
      )
      .subscribe((altitude) => {
        this.propertiesForm.patchValue(altitude);
      });

    /* gestion de l'autocomplétion de la date ou non.
     * autocomplete si date_max non renseignée (creation) ou si date_min = date_max (creation ou edition)
     */
    //date_min part : if date_max is empty or date_min == date_max
    this.propertiesForm
      .get("date_min")
      .valueChanges.pipe(
        distinctUntilChanged(),
        pairwise(),
        filter(
          ([date_min_prev, date_min_new]) =>
            this.propertiesForm.get("date_max").value === null ||
            JSON.stringify(date_min_prev) ===
              JSON.stringify(this.propertiesForm.get("date_max").value)
        ),
        map(([date_min_prev, date_min_new]) => date_min_new)
      )
      .subscribe((date_min) =>
        this.propertiesForm.get("date_max").setValue(date_min)
      );

    //date_max part : only if date_min is empty
    this.propertiesForm
      .get("date_max")
      .valueChanges.pipe(
        distinctUntilChanged(),
        filter(() => this.propertiesForm.get("date_min").value === null)
      )
      .subscribe((date_max) =>
        this.propertiesForm.get("date_min").setValue(date_max)
      );

    // AUTOCORRECTION de hour
    // si le champ est une chaine vide ('') on reset la valeur null
    this.propertiesForm
      .get("hour_min")
      .valueChanges.pipe(filter((hour) => hour && hour.length == 0))
      .subscribe((hour) => {
        this.propertiesForm.get("hour_min").reset();
      });

    this.propertiesForm
      .get("hour_max")
      .valueChanges.pipe(filter((hour) => hour && hour.length == 0))
      .subscribe((hour) => {
        this.propertiesForm.get("hour_max").reset();
      });

    // AUTOCOMPLETE DE hour_max par hour_min UNIQUEMENT SI editionMode = FAUX
    this.propertiesForm
      .get("hour_min")
      .valueChanges.pipe(
        filter(
          (hour) =>
            !this.occtaxFormService.editionMode.getValue() && hour != null
        ),
        tap((hour) => console.log(hour))
      )
      .subscribe((hour) => {
        if (
          // autcomplete only if hour max is empty or invalid
          this.propertiesForm.get("hour_max").invalid ||
          this.propertiesForm.get("hour_max").value == null
        ) {
          this.propertiesForm.get("hour_max").setValue(hour);
        }
      });
  }

  /** Get occtax data in order to patch value to the form */
  private get releveValues(): Observable<any> {
    return this.occtaxFormService.occtaxData.pipe(
      tap(() => this.habitatForm.setValue(null)),
      filter((data) => data && data.releve.properties),
      map((data) => data.releve.properties),
      map((releve) => {
        //Parfois il passe 2 fois ici, et la seconde fois la date est déja formattée en objet, si c'est le cas, on saute
        if (typeof releve.date_min !== "object") {
          releve.date_min = this.occtaxFormService.formatDate(releve.date_min);
        }
        if (typeof releve.date_max !== "object") {
          releve.date_max = this.occtaxFormService.formatDate(releve.date_max);
        }

        return releve;
      }),
      tap((releve) => {
        // set habitat form value from
        if (releve.habitat) {
          const habitatFormValue = releve.habitat;
          // set search_name properties to the form
          habitatFormValue["search_name"] =
            habitatFormValue.lb_code + " - " + habitatFormValue.lb_hab_fr;
          this.habitatForm.setValue(habitatFormValue);
        }
      })
    );
  }

  private defaultDateWithToday() {
    if (!ModuleConfig.DATE_FORM_WITH_TODAY) {
      return null;
    } else {
      const today = new Date();
      return {
        year: today.getFullYear(),
        month: today.getMonth() + 1,
        day: today.getDate(),
      };
    }
  }

  getPreviousReleve(previousReleve) {
    if (previousReleve && !ModuleConfig.ENABLE_SETTINGS_TOOLS) {
      return {
        id_dataset: previousReleve.properties.id_dataset,
        observers: previousReleve.properties.observers,
        observers_txt: previousReleve.properties.observers_txt,
        date_min: previousReleve.properties.date_min,
        date_max: previousReleve.properties.date_max,
        hour_min: previousReleve.properties.hour_min,
        hour_max: previousReleve.properties.hour_max,
      };
    }
    return {
      id_dataset: null,
      observers: null,
      observers_txt: null,
      date_min: null,
      date_max: null,
      hour_min: null,
      hour_max: null,
      place_name: null,
      cd_hab: null,
    };
  }

  private get defaultValues(): Observable<any> {
    return this.occtaxFormService
      .getDefaultValues(this.occtaxFormService.currentUser.id_organisme)
      .pipe(
        map((data) => {
          const previousReleve = this.getPreviousReleve(
            this.occtaxFormService.previousReleve
          );
          return {
            // datasetId could be get for get parameters (see releve.component)
            id_dataset:
              this.datasetId ||
              this.occtaxParamS.get("releve.id_dataset") ||
              previousReleve.id_dataset,
            date_min:
              this.occtaxParamS.get("releve.date_min") ||
              previousReleve.date_min ||
              this.defaultDateWithToday(),
            date_max:
              this.occtaxParamS.get("releve.date_max") ||
              previousReleve.date_max ||
              this.defaultDateWithToday(),
            hour_min:
              this.occtaxParamS.get("releve.hour_min") ||
              previousReleve.hour_min,
            hour_max:
              this.occtaxParamS.get("releve.hour_max") ||
              previousReleve.hour_max,
            altitude_min: this.occtaxParamS.get("releve.altitude_min"),
            altitude_max: this.occtaxParamS.get("releve.altitude_max"),
            meta_device_entry: "web",
            comment: this.occtaxParamS.get("releve.comment"),
            observers:
              this.occtaxParamS.get("releve.observers") ||
              previousReleve.observers ||
              (ModuleConfig.observers_txt
                ? null
                : [this.occtaxFormService.currentUser]),
            observers_txt:
              this.occtaxParamS.get("releve.observers_txt") ||
              previousReleve.observers_txt ||
              (ModuleConfig.observers_txt
                ? this.occtaxFormService.currentUser.nom_complet
                : null),
            id_nomenclature_grp_typ:
              this.occtaxParamS.get("releve.id_nomenclature_grp_typ") ||
              data["TYP_GRP"],
            grp_method: this.occtaxParamS.get("releve.grp_method"),
            id_nomenclature_tech_collect_campanule:
              this.occtaxParamS.get(
                "releve.id_nomenclature_tech_collect_campanule"
              ) || data["TECHNIQUE_OBS"],
            id_nomenclature_geo_object_nature:
              this.occtaxParamS.get(
                "releve.id_nomenclature_geo_object_nature"
              ) || data["NAT_OBJ_GEO"],
            additional_fields: {},
          };
        })
      );
  }

  releveFormValue() {
    let value = JSON.parse(JSON.stringify(this.releveForm.value));

    value.properties.date_min = this.dateParser.format(
      value.properties.date_min
    );
    value.properties.date_max = this.dateParser.format(
      value.properties.date_max
    );
    if (!ModuleConfig.observers_txt) {
      value.properties.observers = value.properties.observers.map(
        (observer) => observer.id_role
      );
    }
    /* Champs additionnels - formatter les dates et les nomenclatures */
    this.additionalFieldsForm.forEach((fieldForm: any) => {
      if (fieldForm.type_widget == "date") {
        value.properties.additional_fields[fieldForm.attribut_name] =
          this.dateParser.format(
            value.properties.additional_fields[fieldForm.attribut_name]
          );
      }
    });
    return value;
  }

  setCurrentUser() {
    this.occtaxFormService.editionMode
      ? null
      : [this.occtaxFormService.currentUser];
  }

  submitReleve() {
    const modulePath = this.moduleService.currentModule.module_path;
    this.waiting = true;
    if (this.occtaxFormService.id_releve_occtax.getValue()) {
      //update
      this.occtaxDataService
        .updateReleve(
          this.occtaxFormService.id_releve_occtax.getValue(),
          this.releveFormValue()
        )
        .pipe(tap(() => (this.waiting = false)))
        .subscribe(
          (data: any) => {
            this._commonService.translateToaster(
              "info",
              "Releve.Infos.ReleveModified"
            );
            this.occtaxFormService.replaceReleveData(data);
            this.releveForm.markAsPristine();
            this.router.navigate([`${modulePath}/form`, data.id, "taxons"]);
            this.occtaxFormService.currentTab = "taxons";
          },
          (err) => {
            this.waiting = false;
            this._commonService.translateToaster("error", "ErrorMessage");
          }
        );
    } else {
      // save previous releve
      this.occtaxFormService.previousReleve = JSON.parse(
        JSON.stringify(this.releveForm.value)
      );

      //create
      this.occtaxDataService
        .createReleve(this.releveFormValue())
        .pipe(tap(() => (this.waiting = false)))
        .subscribe(
          (data: any) => {
            this.occtaxFormService.id_releve_occtax.next(data.id);
            this._commonService.translateToaster(
              "info",
              "Releve.Infos.ReleveAdded"
            );
            this.router.navigate([data.id, "taxons"], {
              relativeTo: this.route,
            });
            this.occtaxFormService.currentTab = "taxons";
          },
          (err) => {
            this.waiting = false;
            this._commonService.regularToaster(
              "error",
              "Action non permise:" + err.error
            );
          }
        );
    }
  }

  formatNomenclature(data) {
    let values = [];
    for (let i = 0; i < data.length; i++) {
      data[i].values.forEach((element) => {
        element["nomenclature_mnemonique"] = data[i]["mnemonique"];
        values[element.id_nomenclature] = element;
      });
    }
    return values;
  }

  reset() {
    this.propertiesForm.reset(this.initialValues);
    this.occtaxFormService.disabled = true;
  }
}
