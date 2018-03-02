import { Injectable } from '@angular/core';
import { FormControl, Validators, AbstractControl, ValidationErrors, ValidatorFn } from '@angular/forms';
import { FormGroup } from '@angular/forms/src/model';

@Injectable()
export class FormService {

  constructor(
  ) {
    
   }


  dateValidator(dateMinControl: AbstractControl, dateMaxControl: AbstractControl): ValidatorFn {
    return (formGroup: FormGroup):  {[key: string]: boolean} => {
      const dateMin = dateMinControl.value;
      const dateMax = dateMaxControl.value;
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

  hourAndDateValidator(
    dateMinControl: AbstractControl,
    dateMaxControl: AbstractControl,
    hourMinControl: AbstractControl,
    hourMaxControl: AbstractControl
  ){
    return (formGroup: FormGroup):  {[key: string]: boolean} => {
      const invalidHour = this.invalidHour(
        dateMinControl,
        dateMaxControl,
        hourMinControl,
        hourMaxControl
      )
      return invalidHour ? { 
        'invalidHour': true
      }: null;
    }
  }


  invalidHour(    
    dateMinControl: AbstractControl,
    dateMaxControl: AbstractControl,
    hourMinControl: AbstractControl,
    hourMaxControl: AbstractControl
  ){

    const hourMin = hourMinControl.value;
    const hourMax = hourMaxControl.value;
    const dateMin = dateMinControl.value;
    const dateMax = dateMaxControl.value;
    // if hour min et pas hour max => set error
    if (hourMin && hourMax) {
      const formatedHourMin = hourMin.split(':').map(h => parseInt(h));
      const formatedHourMax = hourMax.split(':').map(h => parseInt(h));
      const formatedDateMin = new Date(dateMin.year, dateMin.month, dateMin.day);
      const formatedDateMax = new Date(dateMax.year, dateMax.month, dateMax.day);
      if (dateMin && dateMax) {
        formatedDateMin.setHours(formatedHourMin[0], formatedHourMin[1]);
        formatedDateMax.setHours(formatedHourMax[0], formatedHourMax[1]);
      }
      return formatedDateMin > formatedDateMax 
    }
    return null
  }
}