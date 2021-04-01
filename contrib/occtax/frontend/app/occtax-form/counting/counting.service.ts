import { Injectable, ComponentRef, ViewContainerRef, ComponentFactory, ComponentFactoryResolver } from "@angular/core";
import {
  FormBuilder,
  FormGroup,
  Validators,
  AbstractControl,
  FormControl
} from "@angular/forms";
import { Observable, Subscription } from "rxjs";
import { map, filter } from "rxjs/operators";

import { OcctaxFormService } from "../occtax-form.service";
import { OcctaxFormParamService } from "../form-param/form-param.service";
import { MediaService } from '@geonature_common/service/media.service';
import { DynamicFormComponent } from "../dynamique-form/dynamic-form.component";
import { DataFormService } from "@geonature_common/form/data-form.service";


@Injectable()
export class OcctaxFormCountingService {
  // public form: FormGroup;
  counting: any;
  synchroCountSub: Subscription;
  public form: FormGroup;
  public dynamicFormGroup: FormGroup;
  componentRefCounting: ComponentRef<any>;
  public dynamicContainerCounting: ViewContainerRef;
  public data : any;

  constructor(
    public dataFormService: DataFormService,
    private fb: FormBuilder,
    private occtaxFormService: OcctaxFormService,
    private occtaxParamS: OcctaxFormParamService,
    private mediaService: MediaService,
    private _resolver: ComponentFactoryResolver,
  ) {}

  createForm(patchWithDefaultValues: boolean = false): FormGroup {
    const form = this.fb.group({
      id_counting_occtax: null,
      id_nomenclature_life_stage: [null, Validators.required],
      id_nomenclature_sex: [null, Validators.required],
      id_nomenclature_obj_count: [null, Validators.required],
      id_nomenclature_type_count: null,
      count_min: [null, [Validators.required, Validators.pattern("[0-9]+")]],
      count_max: [null, [Validators.required, Validators.pattern("[0-9]+")]],
      medias: [[], this.mediaService.mediasValidator()],
    });

    //Ajout du composant dynamique    
    if (this.componentRefCounting){
      //Copy du formGroupDynamique
      const formGroup = new FormGroup({});
      const controls = this.componentRefCounting.instance.formArray.controls;
      
      Object.keys(controls).forEach(key => {
        formGroup.addControl(key, new FormControl(null));
      })
      form.addControl('additional_fields', formGroup);
      
    }

    form.setValidators([this.countingValidator]);

    if (patchWithDefaultValues) {
      this.defaultValues.subscribe((DATA) => form.patchValue(DATA));
      form
        .get("count_min")
        .valueChanges.pipe(
          filter(() => form.get("count_max").dirty === false) //tant que count_max n'a pas été modifié
        )
        .subscribe((count_min) => form.get("count_max").setValue(count_min));
    }

    return form;
  }

  countingValidator(countForm: AbstractControl): { [key: string]: boolean } {
    const countMin = countForm.get("count_min").value;
    const countMax = countForm.get("count_max").value;
    if (countMin && countMax) {
      return countMin > countMax ? { invalidCount: true } : null;
    }
    return null;
  }

  generateAdditionForm(dynamicFormDatasetConfig) {
    if (this.dynamicContainerCounting){
      this.dynamicContainerCounting.clear(); 
     }
    if(dynamicFormDatasetConfig['FORMFIELDS']['COUNTING'].length > 0){
     //A l'initialisation du composant, on charge le formulaire dynamique

      const factory: ComponentFactory<any> = this._resolver.resolveComponentFactory(DynamicFormComponent);
      this.componentRefCounting = this.dynamicContainerCounting.createComponent(factory);
      
      this.dynamicFormGroup = this.fb.group({});      
      
      if(this.form.get('additional_fields')){
        for (const key of Object.keys(this.form.get('additional_fields').value)){
          this.dynamicFormGroup.addControl(key, new FormControl(this.form.get('additional_fields').value[key]));
        }
      }
  
      this.componentRefCounting.instance.formConfigReleveDataSet = dynamicFormDatasetConfig["FORMFIELDS"]["COUNTING"];
      this.componentRefCounting.instance.formArray = this.dynamicFormGroup;
      
      //on insert le formulaire dynamique au form control
        this.form.setControl("additional_fields", this.dynamicFormGroup);
    }
  }

  setAddtionnalFieldsValues(releve, dynamicFormDatasetConfig) {
    dynamicFormDatasetConfig["FORMFIELDS"]["COUNTING"].map((widget) => {
      if(widget.type_widget == "date"){
        releve.t_occurrences_occtax.map((occurrence) => {
          occurrence.cor_counting_occtax.map((counting) => {
            //On peut passer plusieurs fois ici, donc on vérifie que la date n'est pas déja formattée
            if(typeof counting.additional_fields[widget.attribut_name] !== "object" && counting.additional_fields[widget.attribut_name] !== ""){
              counting.additional_fields[widget.attribut_name] = this.occtaxFormService.formatDate(counting.additional_fields[widget.attribut_name]);
            }
            if ( counting.additional_fields[widget.attribut_name] == ""){
              counting.additional_fields[widget.attribut_name] = null;
            }
          })
        })
      }
      //Formattage des nomenclatures
      if(widget.type_widget == "nomenclature"){
        //mise en forme des nomenclatures
        releve.t_occurrences_occtax.forEach(occurrence => {
          occurrence.cor_counting_occtax.forEach(counting => {
            this.dataFormService.getNomenclatures([widget.code_nomenclature_type])
              .subscribe((nomenclatures) => {
                this.occtaxFormService.storeAdditionalNomenclaturesValues(nomenclatures);
                const nomenclature_item = this.occtaxFormService.nomenclatureAdditionnel.find(n => {
                  return n["label_fr"] === counting.additional_fields[widget.attribut_name];
                });
                if(nomenclature_item){
                  counting.additional_fields[widget.attribut_name] = nomenclature_item.id_nomenclature;
                }else{
                  counting.additional_fields[widget.attribut_name] = "";
                }
              });
            })
          })
        }
    })
  }

  private get defaultValues(): Observable<any> {
    return this.occtaxFormService
      .getDefaultValues(this.occtaxFormService.currentUser.id_organisme)
      .pipe(
        map((DATA) => {
          return {
            count_min: this.occtaxParamS.get("counting.count_min") || 1,
            count_max: this.occtaxParamS.get("counting.count_max") || 1,
            id_nomenclature_life_stage:
              this.occtaxParamS.get("counting.id_nomenclature_life_stage") ||
              DATA["STADE_VIE"],
            id_nomenclature_sex:
              this.occtaxParamS.get("counting.id_nomenclature_sex") ||
              DATA["SEXE"],
            id_nomenclature_obj_count:
              this.occtaxParamS.get("counting.id_nomenclature_obj_count") ||
              DATA["OBJ_DENBR"],
            id_nomenclature_type_count:
              this.occtaxParamS.get("counting.id_nomenclature_type_count") ||
              DATA["TYP_DENBR"],
            id_nomenclature_valid_status:
              this.occtaxParamS.get("counting.id_nomenclature_valid_status") ||
              DATA["STATUT_VALID"],
          };
        })
      );
  }
}
