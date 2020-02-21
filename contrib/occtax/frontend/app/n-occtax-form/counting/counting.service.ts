import { Injectable } from "@angular/core";
import {
  FormBuilder,
  FormGroup,
  Validators,
  AbstractControl
} from "@angular/forms";
import { BehaviorSubject } from "rxjs/BehaviorSubject";

import { ModuleConfig } from "../../module.config";
import { FormService } from "@geonature_common/form/form.service";

@Injectable()
export class OcctaxFormCountingService {

  // public form: FormGroup;

  constructor(
    private fb: FormBuilder,
    private coreFormService: FormService,
  ) {
    console.log("couting")
    // this.initForm();
  }

  private get initialValues() {
    return {
      count_min: 1,
      count_max: 1
    };
  }

  createForm(): FormGroup {
    const form = this.fb.group({
      id_nomenclature_life_stage: [null, Validators.required],
      id_nomenclature_sex: [null, Validators.required],
      id_nomenclature_obj_count: [null, Validators.required],
      id_nomenclature_type_count: null,
      count_min: [null, [Validators.required, Validators.pattern("[0-9]+")]],
      count_max: [null, [Validators.required, Validators.pattern("[0-9]+")]],
    });

    form.setValidators([this.countingValidator]);

    form.patchValue(this.initialValues);

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


  reset() {
    //this.form.reset(this.initialValues);
  }

}
