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
    /* Selected */
    if (event.target.checked) {
      // Add a new control in the arrayForm
      formControl.value.push(event.target.value);
    } else {
      /* unselected */
      // find the unselected element

      formControl.value.forEach((val, index) => {
        if (val === event.target.value) {
          // Remove the unselected element from the arrayForm
          formControl.value.splice(index, 1);
        }
      });
    }
  }

  onRadioChange(val, formControl: FormControl) {
    formControl.patchValue(val);
  }
}
