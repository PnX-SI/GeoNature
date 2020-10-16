import { Injectable, ComponentRef, ViewContainerRef, ComponentFactory, ComponentFactoryResolver } from "@angular/core";
import {
  FormBuilder,
  FormGroup,
  Validators,
  AbstractControl,
  FormControl
} from "@angular/forms";
import { Observable, Subscription } from "rxjs";
import { map, filter, tap } from "rxjs/operators";

import { OcctaxFormService } from "../occtax-form.service";
import { OcctaxFormParamService } from "../form-param/form-param.service";
import { MediaService } from '@geonature_common/service/media.service';
import { dynamicFormReleveComponent } from "../dynamique-form-releve/dynamic-form-releve.component";
import { ModuleConfig } from "../../module.config";

@Injectable()
export class OcctaxFormCountingService {
  // public form: FormGroup;
  counting: any;
  synchroCountSub: Subscription;
  
  public dynamicFormGroup: FormGroup;
  componentRefCounting: ComponentRef<any>;
  public dynamicContainerCounting: ViewContainerRef;
  public data : any;

  constructor(
    private fb: FormBuilder,
    private occtaxFormService: OcctaxFormService,
    private occtaxParamS: OcctaxFormParamService,
    private mediaService: MediaService,
    private _resolver: ComponentFactoryResolver
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

    /*if(this.dynamicContainerCounting != undefined){
      this.dynamicContainerCounting.clear(); 
      const factory: ComponentFactory<any> = this._resolver.resolveComponentFactory(dynamicFormReleveComponent);
      this.componentRefCounting = this.dynamicContainerCounting.createComponent(factory);
      
      this.dynamicFormGroup = this.fb.group({});

      this.componentRefCounting.instance.formConfigReleveDataSet = ModuleConfig.add_fields[1]['counting'];
      this.componentRefCounting.instance.formArray = this.dynamicFormGroup;
      
      form.addControl('additional_fields', this.dynamicFormGroup);
    }*/
    /*if (!patchWithDefaultValues){
      if(this.dynamicContainerCounting != undefined){
        this.dynamicContainerCounting.clear(); 
        const factory: ComponentFactory<any> = this._resolver.resolveComponentFactory(dynamicFormReleveComponent);
        this.componentRefCounting = this.dynamicContainerCounting.createComponent(factory);
        
        this.dynamicFormGroup = this.fb.group({});
    
        this.componentRefCounting.instance.formConfigReleveDataSet = ModuleConfig.add_fields[1]['counting'];
        this.componentRefCounting.instance.formArray = this.dynamicFormGroup;
      }
    }*/

    if (this.componentRefCounting){
      //Copy du formGroupDynamique

      //TODO => impossible de récupérer les validators required -> on peut plus valider
      //const formGroup = new FormGroup({}, this.componentRefCounting.instance.formArray.validator, this.componentRefCounting.instance.formArray.asyncValidator);
      const formGroup = new FormGroup({});
      const controls = this.componentRefCounting.instance.formArray.controls;
      Object.keys(controls).forEach(key => {
        //formGroup.addControl(key, new FormControl(null, controls[key].validator, controls[key].asyncValidator));
        formGroup.addControl(key, new FormControl(null));
      })
      //formGroup.reset();

      /*const formGroupDynamique = new FormGroup({});
      for (let key of Object.keys(this.componentRefCounting.instance.formArray.value)) {
        const control = this.componentRefCounting.instance.formArray.controls[key];
        const copyControl = new FormControl({...control.value});
      }*/
      //let formGroupDynamique = this.componentRefCounting.instance.formArray;
      form.addControl('additional_fields', formGroup);
      //formGroup.reset();
    }

    form.setValidators([this.countingValidator]);

    if (patchWithDefaultValues) {
      
      this.defaultValues.subscribe((DATA) => form.patchValue(DATA));
      /*if(form.get('additional_fields')){
        form.get('additional_fields').reset();
      }*/
      form
        .get("count_min")
        .valueChanges.pipe(
          filter(() => form.get("count_max").dirty === false) //tant que count_max n'a pas été modifié
        )
        .subscribe((count_min) => form.get("count_max").setValue(count_min));
    }
    /*MET Champs additionnel*/
    
    /*
    if(this.dynamicContainerCounting != undefined){
      this.dynamicContainerCounting.clear(); 
      const factory: ComponentFactory<any> = this._resolver.resolveComponentFactory(dynamicFormReleveComponent);
      this.componentRefCounting = this.dynamicContainerCounting.createComponent(factory);
      
      this.dynamicFormGroup = this.fb.group({});
  
      this.componentRefCounting.instance.formConfigReleveDataSet = ModuleConfig.add_fields[1]['occurrence'];
      this.componentRefCounting.instance.formArray = this.dynamicFormGroup;
    }*/

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
