import { Injectable } from '@angular/core';
import { FormControl, Validators, AbstractControl, ValidationErrors, ValidatorFn } from '@angular/forms';
import { FormGroup } from '@angular/forms/src/model';

@Injectable()
export class FormService {

  constructor(
  ) {
    
   }

  dateValidator(formGroup: FormGroup):  {[key: string]: boolean} {
    const dateMin = formGroup.controls['date_min'].value;
    const dateMax = formGroup.controls['date_max'].value;
    if (dateMin && dateMax) {
      const formatedDateMin = new Date(dateMin.year, dateMin.month, dateMin.day);
      const formatedDateMax = new Date(dateMax.year, dateMax.month, dateMax.day);
      if (formatedDateMax < formatedDateMin) {
        return {
          'invalidDate': true
          }
      } else {
        return null
      }
    }
    return null
  }
 
}