import { Injectable } from '@angular/core';
import { FormGroup, FormBuilder, FormControl } from '@angular/forms';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';


@Injectable()
export class MetadataSearchFormService {
  public form: FormGroup;
  public rapidSearchControl: FormControl;
  constructor(private _fb: FormBuilder, public dateParser: NgbDateParserFormatter) {

    this.form = this._fb.group({
      'selector': 'ds',
      'uuid': null,
      'name': null,
      'date': null,
      'organism': null,
      'person': null
    })
    this.rapidSearchControl = new FormControl();
  }

  formatFormValue(formValue) {
    const formatedForm = {}
    Object.keys(formValue).forEach(key => {
      if (key == 'date' && formValue['date']) {
        formatedForm['date'] = this.dateParser.format(formValue['date'])
      } else if (formValue[key]) {
        formatedForm[key] = formValue[key]
      }
    })
    return formatedForm;
  }

  resetForm() {
    this.form.reset();
    this.form.patchValue({ 'selector': 'ds' })
  }

}
