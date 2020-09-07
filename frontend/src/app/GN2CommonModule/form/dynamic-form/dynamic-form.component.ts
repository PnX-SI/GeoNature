import { Component, OnInit, Input, Output, EventEmitter, SimpleChanges } from '@angular/core';
import { FormGroup, FormArray, FormControl } from '@angular/forms';
import { DynamicFormService } from '../dynamic-form-generator/dynamic-form.service';
import { AppConfig } from '@geonature_config/app.config'

@Component({
  selector: 'pnx-dynamic-form',
  templateUrl: './dynamic-form.component.html',
  styleUrls: ['./dynamic-form.component.scss']
})
export class DynamicFormComponent implements OnInit {

  @Input() formDef: any;
  @Input() form: FormGroup;

  public appConfig = AppConfig;
  public rand = Math.ceil(Math.random() * 1e10);

  constructor(private _dynformService: DynamicFormService) {}

  ngOnInit() {}

  formDefComp(): any {
    const formDefComp: any = {}
    for (const key of Object.keys(this.formDef)) {
      formDefComp[key] = typeof this.formDef[key] === 'function'
        ? this.formDef[key]({ value: this.form.value, meta: this.formDef.meta, attribut_name: this.formDef.attribut_name  })
        : this.formDef[key]
    }
    this._dynformService.setControl(this.form.controls[this.formDef.attribut_name], formDefComp)
    return formDefComp;
  }

  /** On ne gère ici que les fichiers uniques */
  onFileChange(event) {
    console.log('onFileChange')
    const files: FileList = event.target.files;
    if (files && files.length === 0) {
      return;
    }
    const file: File = files[0];
    const value = {};
    value[this.formDefComp().attribut_name] = file;
    this.form.patchValue(value);
    this.form.patchValue(value);
    // this.form.controls[this.formDefComp().attribut_name].clearValidators();
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
    formControl.setValue(val);
  }

}
