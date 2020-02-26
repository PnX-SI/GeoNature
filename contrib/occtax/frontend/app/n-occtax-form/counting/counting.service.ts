import { Injectable } from "@angular/core";
import {
  FormBuilder,
  FormGroup,
  Validators,
  AbstractControl
} from "@angular/forms";
import { Observable } from "rxjs";
import { map } from "rxjs/operators";

import { ModuleConfig } from "../../module.config";
import { FormService } from "@geonature_common/form/form.service";
import { OcctaxFormService } from '../occtax-form.service';

@Injectable()
export class OcctaxFormCountingService {

  // public form: FormGroup;
  counting: any;

  constructor(
    private fb: FormBuilder,
    private coreFormService: FormService,
    private occtaxFormService: OcctaxFormService,
  ) 
  { }

  private get initialValues() {
    return {
      count_min: 1,
      count_max: 1
    };
  }

  createForm(patchWithDefaultValues: boolean = false): FormGroup {
    const form = this.fb.group({
      id_counting_occtax: null,
      id_nomenclature_life_stage: [null, Validators.required],
      id_nomenclature_sex: [null, Validators.required],
      id_nomenclature_obj_count: [null, Validators.required],
      id_nomenclature_type_count: null,
      count_min: [null, [Validators.required, Validators.pattern("[0-9]+")]],
      count_max: [null, [Validators.required, Validators.pattern("[0-9]+")]],
    });

    form.setValidators([this.countingValidator]);

    form.patchValue(this.initialValues);

    if (patchWithDefaultValues) {
      this.defaultValues.subscribe(DATA=>form.patchValue(DATA));
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

  private get defaultValues(): Observable<any> {
    return this.occtaxFormService.getDefaultValues(this.occtaxFormService.currentUser.id_organisme)
                    .pipe(
                      map(DATA=> {
                        return {
                          id_nomenclature_life_stage: DATA["STADE_VIE"],
                          id_nomenclature_sex: DATA["SEXE"],
                          id_nomenclature_obj_count: DATA["OBJ_DENBR"],
                          id_nomenclature_type_count: DATA["TYP_DENBR"],
                          id_nomenclature_valid_status: DATA["STATUT_VALID"]
                        };
                      })
                    );
  }


  reset() {
    //this.form.reset(this.initialValues);
  }

}
