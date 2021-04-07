import { Injectable, ComponentRef, ViewContainerRef, ComponentFactory, ComponentFactoryResolver } from "@angular/core";
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
import { map, filter, switchMap, tap, pairwise, retry, mergeMap } from "rxjs/operators";
import { CommonService } from "@geonature_common/service/common.service";
import { OcctaxFormService } from "../occtax-form.service";
import { OcctaxFormCountingService } from "../counting/counting.service";
import { OcctaxDataService } from "../../services/occtax-data.service";
import { OcctaxFormParamService } from "../form-param/form-param.service";
import { OcctaxTaxaListService } from "../taxa-list/taxa-list.service";
import { DynamicFormComponent } from "../dynamique-form/dynamic-form.component";
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
  
  public dynamicFormGroup: FormGroup;
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
    private _resolver: ComponentFactoryResolver,
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
      cor_counting_occtax: this.fb.array([], Validators.required),
    });
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
        //Ajout du composant dynamique
        //initialiser les valeurs null à des objets vides, sinon ca pétille
        if(values.additional_fields == null){
          values.additional_fields = {};
        } else if (values.cor_counting_occtax) {
          for (const key of Object.keys(values.cor_counting_occtax)){
            if(values.cor_counting_occtax[key].additional_fields == null){
              values.cor_counting_occtax[key].additional_fields = {};
            }
          }
        }        
        this.form.patchValue(values);
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

    this.setAddtionnalForm();

  }
  
  /** Get occtax data and patch value to the form */
  setAddtionnalForm() {    

    this.occtaxFormService.occtaxData.pipe(
      filter(data => data && data.releve.properties),
       mergeMap(data => {
        this.currentReleve = data.releve.properties;
        this.idDataset = data.releve.properties.dataset.id_dataset;
        return this.dataFormService.getAdditionnalFields({
          'id_dataset':  data.releve.properties.dataset.id_dataset,
          'module_code': ['OCCTAX', 'GEONATURE'],
          'object_code': ['OCCTAX_OCCURENCE', 'OCCTAX_DENOMBREMENT']
        })
       })
      ).subscribe(additionnalFields => {      
        this.occtaxFormService.occurrenceAddFields = [];
        this.occtaxFormService.countingAddFields = [];  
        console.log("TAB COUNTING", this.occtaxFormService.countingAddFields);
                
        additionnalFields.forEach(field => {
          if(field.cor_additionnal && field.cor_additionnal.object) {
            if (field.cor_additionnal.object.code_object == "OCCTAX_OCCURENCE") {              
              this.occtaxFormService.occurrenceAddFields.push(field);
            }
            if (field.cor_additionnal.object.code_object == "OCCTAX_DENOMBREMENT") {
              this.occtaxFormService.countingAddFields.push(field);
            }
          }
        });
        
        // TODO: id_taxa_list 
        // if(dynamicFormDataset && dynamicFormDataset["ID_TAXON_LIST"]){
        //     this.idTaxonList = dynamicFormDataset["ID_TAXON_LIST"];
        // }
        let NOMENCLATURES = [];
        if(this.occtaxFormService.occurrenceAddFields.length > 0){          
          if (this.form.get("additional_fields") == undefined && this.dynamicContainerOccurence){
            //Ajout du composant dynamique
            this.dynamicFormGroup = this.fb.group({});
        
            //on insert le formulaire dynamique au form control
            this.occtaxFormService.createAdditionnalFieldsUI(this.dynamicContainerOccurence, additionnalFields, this.dynamicFormGroup);
            this.form.addControl("additional_fields", this.dynamicFormGroup);

          }
          
          this.occtaxFormService.occurrenceAddFields.forEach((field) => {            
            if(field.type_widget == "date"){
              this.currentReleve.t_occurrences_occtax.forEach(occurrence => {
                //On peut passer plusieurs fois ici, donc on vérifie que la date n'est pas déja formattée
                if(typeof occurrence.additional_fields[field.attribut_name] !== "object"){
                  occurrence.additional_fields[field.attribut_name] = this.occtaxFormService.formatDate(
                    occurrence.additional_fields[field.attribut_name]
                  );
                }
              });
            }
            //Formattage des nomenclatures
            if(field.type_widget == "nomenclature"){
              //Charger les nomenclatures dynamiques dans un tableau
              if (!NOMENCLATURES[field.code_nomenclature_type]){
                NOMENCLATURES.push(field.code_nomenclature_type);
              }
              
              //mise en forme des nomenclatures
              this.currentReleve.t_occurrences_occtax.forEach((occurrence) => {
                this.dataFormService.getNomenclatures([field.code_nomenclature_type])
                  .subscribe((nomenclatures) => {
                    this.occtaxFormService.storeAdditionalNomenclaturesValues(nomenclatures);
                    const nomenclature_item = this.occtaxFormService.nomenclatureAdditionnel.find(n => {
                     return  n["label_fr"] === occurrence.additional_fields[field.attribut_name] ;
                    }); 
                    if(nomenclature_item){
                      occurrence.additional_fields[field.attribut_name] = nomenclature_item.id_nomenclature;
                    } else{
                      occurrence.additional_fields[field.attribut_name] = "";
                    }
                  });
                })
              }
          })
        }
        
        if(this.occtaxFormService.countingAddFields){                    
          //A l'initialisation du composant, on charge le formulaire dynamique
            this.occtaxFormCountingService.generateAdditionForm(this.occtaxFormService.countingAddFields)
            this.occtaxFormCountingService.setAddtionnalFieldsValues(
              this.currentReleve, this.occtaxFormService.countingAddFields
            )
        }
      })
  }

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
    this.formDynamicValue();

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
        .createOccurrence(id_releve, this.form.value)
        .pipe(retry(3))
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

  formDynamicValue(){
    //Mise en forme des champs additionnels
      this.occtaxFormService.occurrenceAddFields.forEach((field) => {
        if(field.type_widget == "date"){
          this.form.value.additional_fields[field.attribut_name] = this.dateParser.format(
            this.form.value.additional_fields[field.attribut_name]
          );
        }
        if(field.type_widget == "nomenclature"){
          console.log(this.occtaxFormService.nomenclatureAdditionnel);
          console.log(this.form.value.additional_fields[field.attribut_name]);
          
          
          // set the label_fr nomenclature in the posted additional data
          const nomenclature_item =  this.occtaxFormService.nomenclatureAdditionnel.find( n => {
            return n["id_nomenclature"] === this.form.value.additional_fields[field.attribut_name];
          })
          if(nomenclature_item){
            this.form.value.additional_fields[field.attribut_name] = nomenclature_item.label_fr;
          }else{
            this.form.value.additional_fields[field.attribut_name] = "";
          }
        }
      })

      this.occtaxFormService.countingAddFields.forEach(field => {
        if(field.type_widget == "date"){
          this.form.value.cor_counting_occtax.forEach(counting => {
            counting.additional_fields[field.attribut_name] = this.dateParser.format(
              counting.additional_fields[field.attribut_name]
            );
          })
        }
        if(field.type_widget == "nomenclature"){
          // set the label_fr nomenclature in the posted additional data
          this.form.value.cor_counting_occtax.forEach(counting => {              
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
          this.form.value.cor_counting_occtax.map(counting => {
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
