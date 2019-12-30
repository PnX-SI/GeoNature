import { Injectable } from '@angular/core';
import { AbstractControl, ValidatorFn } from '@angular/forms';
import { FormGroup, FormControl } from '@angular/forms/src/model';
import { Subscription } from 'rxjs';

@Injectable()
export class FormService {
  constructor() {}

  dateValidator(dateMinControl: AbstractControl, dateMaxControl: AbstractControl): ValidatorFn {
    return (formGroup: FormGroup): { [key: string]: boolean } => {
      const dateMin = dateMinControl.value;
      const dateMax = dateMaxControl.value;
      if (dateMin && dateMax) {
        const formatedDateMin = new Date(dateMin.year, dateMin.month, dateMin.day);
        const formatedDateMax = new Date(dateMax.year, dateMax.month, dateMax.day);
        if (formatedDateMax < formatedDateMin) {
          return {
            invalidDate: true
          };
        } else {
          return null;
        }
      }
      return null;
    };
  }

  altitudeValidator(altiMinControl: AbstractControl, altMaxControl: AbstractControl): ValidatorFn {
    return (formGroup: FormGroup): { [key: string]: boolean } => {
      const altMin = altiMinControl.value;
      const altMax = altMaxControl.value;
      if (altMin && altMax && altMin > altMax) {
        return {
          invalidAlt: true
        };
      } else {
        return null;
      }
    };
  }

  hourAndDateValidator(
    dateMinControl: AbstractControl,
    dateMaxControl: AbstractControl,
    hourMinControl: AbstractControl,
    hourMaxControl: AbstractControl
  ) {
    return (formGroup: FormGroup): { [key: string]: boolean } => {
      const invalidHour = this.invalidHour(
        dateMinControl,
        dateMaxControl,
        hourMinControl,
        hourMaxControl
      );
      return invalidHour
        ? {
            invalidHour: true
          }
        : null;
    };
  }

  invalidHour(
    dateMinControl: AbstractControl,
    dateMaxControl: AbstractControl,
    hourMinControl: AbstractControl,
    hourMaxControl: AbstractControl
  ) {
    const hourMin = hourMinControl.value;
    const hourMax = hourMaxControl.value;
    const dateMin = dateMinControl.value;
    const dateMax = dateMaxControl.value;
    // if hour min et pas hour max => set error
    if (hourMin && !hourMax) {
      return true;
      // if hour min et hour max => check validity
    } else if (dateMin && dateMax && hourMin && hourMax) {
      const formatedHourMin = hourMin.split(':').map(h => parseInt(h));
      const formatedHourMax = hourMax.split(':').map(h => parseInt(h));
      const formatedDateMin = new Date(dateMin.year, dateMin.month, dateMin.day);
      const formatedDateMax = new Date(dateMax.year, dateMax.month, dateMax.day);
      if (dateMin && dateMax) {
        formatedDateMin.setHours(formatedHourMin[0], formatedHourMin[1]);
        formatedDateMax.setHours(formatedHourMax[0], formatedHourMax[1]);
      }
      return formatedDateMin > formatedDateMax;
    }
    return null;
  }

  taxonValidator(taxControl: AbstractControl) {
    const currentTaxon = taxControl.value;
    if (!currentTaxon) {
      return null;
    } else if (!currentTaxon.cd_nom && !currentTaxon.search_name) {
      return {
        invalidTaxon: true
      };
    } else {
      return null;
    }
  }

  searchLocally(searchPatern, data) {
    const savedData = data;
    let filteredData = [];
    filteredData = savedData.filter(el => {
      const isIn = el.label_default.toUpperCase().indexOf(searchPatern.toUpperCase());
      return isIn !== -1;
    });
    return filteredData;
  }

  autoCompleteDate(
    formControl,
    dateMinControlName = 'date_min',
    dateMaxControlName = 'date_max'
  ): Subscription {
    // date max autocomplete
    const dateMinControl: FormControl = formControl.get(dateMinControlName);
    const subscription = dateMinControl.valueChanges.subscribe(newvalue => {
      // Get mindate and maxdate value before mindate change
      let oldmindate = formControl.value['date_min'];
      let oldmaxdate = formControl.value['date_max'];

      // Compare the dates before the change of the datemin.
      // If datemin and datemax were equal, maintain this equality
      // If they don't, do nothing
      // oldmaxdate and oldmindate are objects. Strigify it for a right comparison
      if (oldmindate) {
        if (JSON.stringify(oldmaxdate) === JSON.stringify(oldmindate) || oldmaxdate == null) {
          formControl.patchValue({
            date_max: newvalue
          });
        }
        // if olddatminDate is null => fill dateMax
      } else {
        formControl.patchValue({
          date_max: newvalue
        });
      }
    });
    return subscription;
  }
}
