import { Injectable, ComponentRef, ViewContainerRef, ComponentFactoryResolver } from "@angular/core";
import {
  FormBuilder,
  FormGroup,
  Validators,
  FormArray,
  ValidatorFn,
  ValidationErrors,
  AbstractControl,
} from "@angular/forms";
import { BehaviorSubject, Observable } from "rxjs";
import { map, filter, switchMap, tap, pairwise, retry, concatMap, mergeMap } from "rxjs/operators";
import { CommonService } from "@geonature_common/service/common.service";
import { OcctaxFormService } from "../occtax-form.service";
import { OcctaxFormCountingService } from "../counting/counting.service";
import { OcctaxDataService } from "../../services/occtax-data.service";
import { OcctaxFormParamService } from "../form-param/form-param.service";
import { OcctaxTaxaListService } from "../taxa-list/taxa-list.service";
import { ModuleConfig } from "../../module.config";
import { NgbDateParserFormatter } from "@ng-bootstrap/ng-bootstrap";
import { DataFormService } from "@geonature_common/form/data-form.service";

@Injectable()
export class OcctaxFormOccurrenceService {
  public form: FormGroup;
  public taxref: BehaviorSubject<any> = new BehaviorSubject(null);
  public occurrence: BehaviorSubject<any> = new BehaviorSubject(null);
  public currentReleve: any;
  public existProof_DATA: Array<any> = [];
  public saveWaiting: boolean = false;
  public additionnalFormLoaded: boolean = false;
  
  componentRefOccurence: ComponentRef<any>;
  public dynamicContainerOccurence: ViewContainerRef;
  public data : any;
  public idDataset : number;


  public idTaxonList: number;
  public formFieldsStatus: any;

  constructor(
    private fb: FormBuilder,
    private commonService: CommonService,
    private occtaxFormService: OcctaxFormService,
    private occtaxFormCountingService: OcctaxFormCountingService,
    private occtaxDataService: OcctaxDataService,
    private occtaxParamS: OcctaxFormParamService,
    private occtaxTaxaListService: OcctaxTaxaListService,
    private dateParser: NgbDateParserFormatter,
    private dataFormService: DataFormService,
  ) {
    this.initForm();
    this.setObservables();
  }

  initForm(): void {
    this.form = this.fb.group({
      id_nomenclature_obs_technique: [null, Validators.required],
      id_nomenclature_bio_condition: [null, Validators.required],
      id_nomenclature_bio_status: null,
      id_nomenclature_naturalness: null,
      id_nomenclature_exist_proof: null,
      id_nomenclature_behaviour: null,
      id_nomenclature_observation_status: null,
      id_nomenclature_blurring: null,
      id_nomenclature_source_status: null,
      determiner: null,
      id_nomenclature_determination_method: null,
      nom_cite: [null, Validators.required],
      cd_nom: [null, Validators.required],
      meta_v_taxref: null,
      sample_number_proof: null,
      digital_proof: null,
      non_digital_proof: null,
      comment: null,
      additional_fields: this.fb.group({}),
      cor_counting_occtax: this.fb.array([], Validators.required),
    });
    this.dataFormService.getAdditionnalFields({
      'module_code': ['OCCTAX', 'GEONATURE'],
      'object_code': 'OCCTAX_DENOMBREMENT',
      "id_dataset": "null"
    }).subscribe(additionnalFields => {
      
      this.occtaxFormService.globalOccurrenceAddFields = additionnalFields;
    })
  }

  /**
   * Initialise les observables pour la mise en place des actions automatiques
   **/
  private setObservables() {
    //patch le form par les valeurs par defaut si creation
    this.occurrence
      .pipe(
        tap(() => {
          //On vide préalablement le FormArray //.clear() existe en angular 8
          this.clearFormArray(
            this.form.get("cor_counting_occtax") as FormArray
          );
        }),
        switchMap((occurrence) => {
          //on oriente la source des données pour patcher le formulaire
          return occurrence ? this.occurrence : this.defaultValues;
        }),
        tap((occurrence) => {
          //mise en place des countingForm
          if (
            !occurrence.id_occurrence_occtax ||
            !occurrence.cor_counting_occtax ||
            occurrence.cor_counting_occtax.length === 0
          ) {
            //si nouvelle occurrence ou si absence de dénombrement on ajoute par defaut un form de denombrement
            this.addCountingForm(true); //true => on patch le form avec les valeurs par defauts
          } else {
            occurrence.cor_counting_occtax.forEach((c, i) => {
              this.addCountingForm(false); //false => on ne patch pas le form avec les valeurs par defauts
            });
          }
        }),
      )
      .subscribe((values) => {
      

        this.setAddtionnalForm(Object.assign({}, values)).subscribe(editedOccurrence => {               
          this.form.patchValue(editedOccurrence);
        })

      });


    //Gestion des erreurs pour les preuves d'existence
    this.form
      .get("id_nomenclature_exist_proof")
      .valueChanges.pipe(
        map((id_nomenclature: number): string => {
          return this.getCdNomenclatureById(
            id_nomenclature,
            this.existProof_DATA
          );
        })
      )
      .subscribe((cd_nomenclature: string) => {
        if (cd_nomenclature == "1") {
          this.form.setValidators(proofRequiredValidator);
          this.form
            .get("digital_proof")
            .setValidators(
              ModuleConfig.digital_proof_validator ?
                Validators.pattern("^(http://|https://|ftp://){1}.+$") :
                []
            );
          this.form.get("non_digital_proof").setValidators([]);

        } else {
          this.form.setValidators([]);
          this.form.get("digital_proof").setValidators(proofNotNullValidator);
          this.form
            .get("non_digital_proof")
            .setValidators(proofNotNullValidator);
        }
        this.form.updateValueAndValidity();
        this.form.get("digital_proof").updateValueAndValidity();
        this.form.get("non_digital_proof").updateValueAndValidity();
      });

    //reset digital_proof à null si texte vide : ''
    this.form
      .get("digital_proof")
      .valueChanges.pipe(
        filter((val) => val !== null), //filtre la valeur null
        pairwise(),
        filter(([prev, next]: [string, string]) => prev !== next),
        map(([prev, next]: [string, string]) => {
          return next.length > 0 ? next : null;
        })
      )
      .subscribe((val) => this.form.get("digital_proof").setValue(val));

    //reset non_digital_proof à null si texte vide : ''
    this.form
      .get("non_digital_proof")
      .valueChanges.pipe(
        filter((val) => val !== null), //filtre la valeur null
        pairwise(),
        filter(([prev, next]: [string, string]) => prev !== next),
        map(([prev, next]: [string, string]) => {
          return next.length > 0 ? next : null;
        })
      )
      .subscribe((val) => this.form.get("non_digital_proof").setValue(val));


  }

  getAdditionnalForm(): Observable<any> {
    // TODO RELOAD ONLY IF DATASET HAS CHANGED
    return this.occtaxFormService.occtaxData.pipe(
      filter(data => data && data.releve.properties),
       concatMap(data => {   
        this.currentReleve = data.releve.properties;
        this.idDataset = data.releve.properties.dataset.id_dataset;
        return this.dataFormService.getAdditionnalFields({
          'id_dataset':  data.releve.properties.dataset.id_dataset,
          'module_code': ['OCCTAX', 'GEONATURE'],
          'object_code': ['OCCTAX_OCCURENCE', 'OCCTAX_DENOMBREMENT']
        })
       })
      ).map(additionnalFields => {
        this.occtaxFormService.globalOccurrenceAddFields = this.occtaxFormService.clearFormerAdditonnalFields(
          this.occtaxFormService.globalOccurrenceAddFields,
          this.occtaxFormService.datasetReleveAddFields,
          additionnalFields
        );
        this.occtaxFormService.globalCountingAddFields = this.occtaxFormService.clearFormerAdditonnalFields(
          this.occtaxFormService.globalCountingAddFields,
          this.occtaxFormService.datasetCountingAddFields,
          additionnalFields
        );
        this.occtaxFormService.datasetOccurrenceAddFields = [];
        this.occtaxFormService.datasetCountingAddFields = [];
        additionnalFields.forEach(field => {
          field.objects.forEach(object => {
            if (object.code_object == "OCCTAX_OCCURENCE") {              
              this.occtaxFormService.datasetOccurrenceAddFields.push(field);
            }
            if (object.code_object == "OCCTAX_DENOMBREMENT") {
              this.occtaxFormService.datasetCountingAddFields.push(field);
            }            
          });

        });
        
        this.occtaxFormService.globalOccurrenceAddFields = this.occtaxFormService.globalOccurrenceAddFields.concat(
          this.occtaxFormService.datasetOccurrenceAddFields
        )
        this.occtaxFormService.globalCountingAddFields = this.occtaxFormService.globalCountingAddFields.concat(
          this.occtaxFormService.datasetCountingAddFields
        )

        return {
          "occurrenceAddFields": this.occtaxFormService.datasetOccurrenceAddFields,
          "countingAddFields": this.occtaxFormService.datasetCountingAddFields,
        }
      },
      );
  }
  
  /** Get occtax data and patch value to the form */
  setAddtionnalForm(occurrenceValue): Observable<any> {
    return this.getAdditionnalForm().pipe(
      mergeMap(addFields => {
        const {occurrenceAddFields, countingAddFields} = addFields;
  
 
        // load all npmenclature
        const nomenclature_mnemonique_types = [];
        [...occurrenceAddFields, ...countingAddFields].forEach(field => {
          if(field.type_widget === 'nomenclature') {
            nomenclature_mnemonique_types.push(field.code_nomenclature_type)
          }
        })
        return this.dataFormService.getNomenclatures(nomenclature_mnemonique_types).map(nomenclatures => {
          this.occtaxFormService.storeAdditionalNomenclaturesValues(nomenclatures);
          if(occurrenceValue.additional_fields) {
            occurrenceAddFields.forEach(field => {
              if(field.type_widget == 'nomenclature') {                
                const nomenclature_item = this.occtaxFormService.nomenclatureAdditionnel.find(n => {              
                  return n.MNEMONIQUE_TYPE === field.code_nomenclature_type && n["label_fr"] === occurrenceValue.additional_fields[field.attribut_name] ;
                }); 
                occurrenceValue.additional_fields[field.attribut_name] = nomenclature_item ? nomenclature_item.id_nomenclature: ""; 
              }

            });
          }
          
          if(occurrenceValue.cor_counting_occtax) {
            occurrenceValue.cor_counting_occtax.forEach(counting => {
              if(counting.additional_fields) {
                countingAddFields.forEach(field => {
                  if(field.type_widget == 'nomenclature') {
                    const nomenclature_item = this.occtaxFormService.nomenclatureAdditionnel.find(n => {              
                      return n.MNEMONIQUE_TYPE === field.code_nomenclature_type && n["label_fr"] === counting.additional_fields[field.attribut_name] ;
                    }); 
                    counting.additional_fields[field.attribut_name] = nomenclature_item ? nomenclature_item.id_nomenclature: ""; 
                  }
  
                });
              }
              
            });
          }

          return occurrenceValue;
        })
      })
    ) 

    
    // if(countingAddFields.length > 0){
    //     this.occtaxFormCountingService.generateAdditionForm(countingAddFields)
    //     this.form.value.cor_counting_occtax.forEach((counting, index) => {
    //       this.occtaxFormCountingService.setAddtionnalFieldsValues(
    //         this.form.controls.cor_counting_occtax.controls[index], 
    //         countingAddFields
    //       )
    //     });

    // }
  }

  // let NOMENCLATURES = [];
  // if(occurrenceAddFields && occurrenceAddFields.length > 0){             
  //   if (this.form.get("additional_fields") == undefined && this.dynamicContainerOccurence){
  //     this.dynamicFormGroup = this.fb.group({});
  //     this.occtaxFormService.createAdditionnalFieldsUI(
  //       this.dynamicContainerOccurence, 
  //       occurrenceAddFields, 
  //       this.dynamicFormGroup
  //     );
  //     this.form.addControl("additional_fields", this.dynamicFormGroup);
  //   }
  //   occurrenceAddFields.forEach(field => {        
  //     if(field.type_widget == "date"){
  //       this.currentReleve.t_occurrences_occtax.forEach(occurrence => {
  //         //On peut passer plusieurs fois ici, donc on vérifie que la date n'est pas déja formattée
  //         if(typeof occurrence.additional_fields[field.attribut_name] !== "object"){
  //           occurrence.additional_fields[field.attribut_name] = this.occtaxFormService.formatDate(
  //             occurrence.additional_fields[field.attribut_name]
  //           );
  //         }
  //       });
  //     }
  //     //Formattage des nomenclatures
  //     if(field.type_widget == "nomenclature"){
  //       //Charger les nomenclatures dynamiques dans un tableau
  //       if (!NOMENCLATURES[field.code_nomenclature_type]){
  //         NOMENCLATURES.push(field.code_nomenclature_type);
  //       }

  //       this.dataFormService.getNomenclatures([field.code_nomenclature_type]).pipe(
  //         map((nomenclatures) => {
  //           this.occtaxFormService.storeAdditionalNomenclaturesValues(nomenclatures);
  //           const nomenclature_item = this.occtaxFormService.nomenclatureAdditionnel.find(n => {              
  //             return  n["label_fr"] === this.form.value.additional_fields[field.attribut_name] ;
  //           }); 
            
  //           const nomenclature_value = nomenclature_item ? nomenclature_item.id_nomenclature: "";
  //           console.log("HEYYY", nomenclature_value);

  //           occurrenceValue.additional_fields[field.attribut_name] = nomenclature_value;
  //         })
  //       )

  //       }
  //   })
  // }
  // return "COUCOU";


  private get defaultValues(): Observable<any> {
    return this.occtaxFormService
      .getDefaultValues(this.occtaxFormService.currentUser.id_organisme)
      .pipe(
        map((DATA) => {
          return {
            determiner:
              this.occtaxParamS.get("occurrence.determiner") ||
              this.occtaxFormService.currentUser.nom_complet,
            sample_number_proof: this.occtaxParamS.get(
              "occurrence.sample_number_proof"
            ),
            digital_proof: this.occtaxParamS.get("occurrence.digital_proof"),
            non_digital_proof: this.occtaxParamS.get("occurrence.non_digital_proof"),
            comment: this.occtaxParamS.get("occurrence.comment"),
            id_nomenclature_bio_condition:
              this.occtaxParamS.get(
                "occurrence.id_nomenclature_bio_condition"
              ) || DATA["ETA_BIO"],
            id_nomenclature_naturalness:
              this.occtaxParamS.get("occurrence.id_nomenclature_naturalness") ||
              DATA["NATURALITE"],
            id_nomenclature_obs_technique:
              this.occtaxParamS.get("occurrence.id_nomenclature_obs_technique") ||
              DATA["METH_OBS"],
            id_nomenclature_bio_status:
              this.occtaxParamS.get("occurrence.id_nomenclature_bio_status") ||
              DATA["STATUT_BIO"],
            id_nomenclature_exist_proof:
              this.occtaxParamS.get("occurrence.id_nomenclature_exist_proof") ||
              DATA["PREUVE_EXIST"],
            id_nomenclature_determination_method:
              this.occtaxParamS.get(
                "occurrence.id_nomenclature_determination_method"
              ) || DATA["METH_DETERMIN"],
            id_nomenclature_observation_status:
              this.occtaxParamS.get(
                "occurrence.id_nomenclature_observation_status"
              ) || DATA["STATUT_OBS"],
            id_nomenclature_blurring:
              this.occtaxParamS.get("occurrence.id_nomenclature_blurring") ||
              DATA["DEE_FLOU"],
            id_nomenclature_source_status:
              this.occtaxParamS.get(
                "occurrence.id_nomenclature_source_status"
              ) || DATA["STATUT_SOURCE"],
            id_nomenclature_behaviour:
              this.occtaxParamS.get(
                "occurrence.id_nomenclature_behaviour"
              ) || DATA["OCC_COMPORTEMENT"],
          };
        })
      );
  }

  addCountingForm(patchWithDefaultValue: boolean = false): void {
    (this.form.get("cor_counting_occtax") as FormArray).push(
      this.occtaxFormCountingService.createForm(patchWithDefaultValue)
    );
  }

  getCdNomenclatureById(IdNomenclature, DATA) {
    //currentCD = null;
    let i = 0;
    while (i < DATA.length) {
      if (DATA[i].id_nomenclature == IdNomenclature) {
        return DATA[i].cd_nomenclature;
      }
      i++;
    }
    return null;
  }


  submitOccurrence() {
    let formValue = Object.assign({}, this.form.value)
    
    formValue = this.transformDynamicFormValues(formValue);

    let id_releve = this.occtaxFormService.id_releve_occtax.getValue();
    let TEMP_ID_OCCURRENCE = this.uuidv4();

    this.occtaxTaxaListService.addOccurrenceInProgress(
      TEMP_ID_OCCURRENCE,
      this.occurrence.getValue() !== null
        ? Object.assign(this.occurrence.getValue(), this.form.value)
        : this.form.value //pour gerer la modification si erreur
    );

    if (
      this.occurrence.getValue() &&
      this.occurrence.getValue().id_occurrence_occtax
    ) {
      //update
      this.occtaxDataService
        .updateOccurrence(
          this.occurrence.getValue().id_occurrence_occtax,
          this.form.value
        )
        .pipe(retry(3))
        .subscribe(
          (occurrence) => {
            this.occtaxTaxaListService.removeOccurrenceInProgress(
              TEMP_ID_OCCURRENCE
            );
            this.commonService.translateToaster("info", "Taxon.UpdateDone");
            this.occtaxFormService.replaceOccurrenceData(occurrence);
          },
          (error) => {
            this.commonService.translateToaster("error", "ErrorMessage");
            this.occtaxTaxaListService.errorOccurrenceInProgress(
              TEMP_ID_OCCURRENCE
            );
          }
        );
    } else {
      //create      
      this.occtaxDataService
        .createOccurrence(id_releve, formValue)
        .subscribe(
          (occurrence) => {            
            this.occtaxTaxaListService.removeOccurrenceInProgress(
              TEMP_ID_OCCURRENCE
            );
            this.commonService.translateToaster("info", "Taxon.CreateDone");
            this.occtaxFormService.addOccurrenceData(occurrence);
          },
          (error) => {
            this.commonService.translateToaster("error", "ErrorMessage");
            this.occtaxTaxaListService.errorOccurrenceInProgress(
              TEMP_ID_OCCURRENCE
            );
          }
        );
    }
    //vide le formulaire
    this.reset();
  }

  deleteOccurrence(occurrence) {
    this.occtaxDataService
      .deleteOccurrence(occurrence.id_occurrence_occtax)
      .subscribe(
        (confirm: boolean) => {
          this.occtaxFormService.removeOccurrenceData(
            occurrence.id_occurrence_occtax
          );
          this.commonService.translateToaster("info", "Taxon.DeleteDone");
        },
        (error) => {
          this.commonService.translateToaster("error", "ErrorMessage");
        }
      );
  }

  transformDynamicValuesBis(occurrence, occAddtionnalFields, countingAddFelds) {
    occAddtionnalFields.forEach(field => {
        if(field.type_widget == "nomenclature"){
        
        }
    });
  }

  /**
   * Transform formValue in order to post it or to edit it
   * If edit = true: Transform nomenclature from label to ID
   * If edit = false: Transform nomenclature from ID to label
   * @param formValue 
   * @param edit 
   * @returns 
   */
  transformDynamicFormValues(formValue, edit = true){
    //Mise en forme des champs additionnels
    this.occtaxFormService.globalOccurrenceAddFields.forEach((field) => {
        if(field.type_widget == "date"){
          formValue.additional_fields[field.attribut_name] = this.dateParser.format(
            formValue.additional_fields[field.attribut_name]
          );
        }
        if(field.type_widget == "nomenclature"){
          
          // set the label_fr nomenclature in the posted additional data
          const nomenclature_item =  this.occtaxFormService.nomenclatureAdditionnel.find( n => {            
            return n["id_nomenclature"] === formValue.additional_fields[field.attribut_name];
          })
          if(nomenclature_item){
            formValue.additional_fields[field.attribut_name] = nomenclature_item.label_fr;
          }else{
            formValue.additional_fields[field.attribut_name] = "";
          }          
        }
      })
      const countingAddFields = [
        ...this.occtaxFormService.globalCountingAddFields,
        ...this.occtaxFormService.datasetCountingAddFields
      ]
      countingAddFields.forEach(field => {
        if(field.type_widget == "date"){
          formValue.cor_counting_occtax.forEach(counting => {
            counting.additional_fields[field.attribut_name] = this.dateParser.format(
              counting.additional_fields[field.attribut_name]
            );
          })
        }
        if(field.type_widget == "nomenclature"){
          // set the label_fr nomenclature in the posted additional data
          formValue.cor_counting_occtax.forEach(counting => {   
                       
            const nomenclature_item = this.occtaxFormService.nomenclatureAdditionnel.find(n => {
              return n["id_nomenclature"] === counting.additional_fields[field.attribut_name];
            });              
            if(nomenclature_item){
              counting.additional_fields[field.attribut_name] = nomenclature_item.label_fr;
            }else{
              counting.additional_fields[field.attribut_name] = "";
            }
          })
        }
        if(field.type_widget == "medias"){
          //Pour le moment, ce n'est pas possible d'ajouter des médias dans le formulaire dynmique
          //Champs additionnel de type media, On  l'enregistre dans les medias pour plus de maintenabilité et le gérer comme tout type de média
          formValue.cor_counting_occtax.map(counting => {
            if (counting.additional_fields[field.attribut_name]){
              counting.additional_fields[field.attribut_name].forEach((media, i) => {
                counting.additional_fields[field.attribut_name] = null;
                counting.medias.push(media);
              });
            }
            delete counting.additional_fields[field.attribut_name];
          })
        }
      })
    return formValue
  }

  reset() {
    this.form.reset();
    this.occurrence.next(null);
  }

  private clearFormArray(formArray: FormArray) {
    while (formArray.length !== 0) {
      formArray.removeAt(0);
    }
  }

  private uuidv4() {
    return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function (
      c
    ) {
      var r = (Math.random() * 16) | 0,
        v = c == "x" ? r : (r & 0x3) | 0x8;
      return v.toString(16);
    });
  }
}

export const proofRequiredValidator: ValidatorFn = (
  control: FormGroup
): ValidationErrors | null => {
  const digital_proof = control.get("digital_proof");
  const non_digital_proof = control.get("non_digital_proof");

  if (
    digital_proof &&
    non_digital_proof &&
    digital_proof.value === null &&
    non_digital_proof.value === null
  ) {
    return { proofRequired: true };
  }

  return null;
};

export function proofNotNullValidator(
  control: AbstractControl
): { [key: string]: boolean } | null {
  if (control.value !== null) {
    return { proofNotNull: true };
  }
  return null;
}
