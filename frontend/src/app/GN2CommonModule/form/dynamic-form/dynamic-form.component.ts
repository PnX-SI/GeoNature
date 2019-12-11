import { Component, OnInit, Input } from '@angular/core';
import { FormGroup, FormArray, FormControl } from '@angular/forms';

@Component({
  selector: 'pnx-dynamic-form',
  templateUrl: './dynamic-form.component.html',
  styleUrls: ['./dynamic-form.component.scss']
})
export class DynamicFormComponent implements OnInit {
  @Input() formDef: any;
  @Input() form: FormGroup;

  constructor() {}

  ngOnInit() {}

  onCheckChange(event, formControl: FormControl) {
    const currentFormValue = Object.assign([], formControl.value);
    /* Selected */
    if (event.target.checked) {
      // Add a new control in the arrayForm
      currentFormValue.push(event.target.value);
      // patch value to declench validators
      formControl.patchValue(currentFormValue);
      console.log(event.target.value);
    } else {
      //find the unselected element
      currentFormValue.forEach((val, index) => {
        if (val === event.target.value) {
          // Remove the unselected element from the arrayForm
          currentFormValue.splice(index, 1);
        }
      });
      // patch value to declench validators
      formControl.patchValue(currentFormValue);
    }
  }

  onRadioChange(val, formControl: FormControl) {
    formControl.patchValue(val);
  }
}
