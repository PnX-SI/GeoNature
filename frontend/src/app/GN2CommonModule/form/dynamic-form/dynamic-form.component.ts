import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { FormGroup, FormArray, FormControl } from '@angular/forms';

@Component({
  selector: 'pnx-dynamic-form',
  templateUrl: './dynamic-form.component.html',
  styleUrls: ['./dynamic-form.component.scss']
})
export class DynamicFormComponent implements OnInit {
  @Input() formDef: any;
  @Input() form: FormGroup;

  @Output() fileChange = new EventEmitter<any>();

  constructor() {}

  ngOnInit() {}

  onFileChange(event) {
    console.log('onFileChange', event)
    const files: FileList = event.target.files;
    if (files && files.length === 0) {
      return;
    }
    const file: File = files[0];
    this.fileChange.emit({file, attribut_name: this.formDef.attribut_name});
  }

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
      // find the unselected element
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
