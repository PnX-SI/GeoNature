import { Injectable } from '@angular/core';
import { UntypedFormGroup, UntypedFormBuilder, UntypedFormControl } from '@angular/forms';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
@Injectable()
export class MetadataSearchFormService {
  public form: UntypedFormGroup;
  public rapidSearchControl: UntypedFormControl;
  constructor(
    private _fb: UntypedFormBuilder,
    public dateParser: NgbDateParserFormatter
  ) {
    this.form = this._fb.group({
      selector: 'ds',
      uuid: null,
      name: null,
      date: null,
      organism: null,
      person: null,
      codeTypeArea: null,
    });
    this.rapidSearchControl = new UntypedFormControl();
  }

  formatFormValue(formValue) {
    const formatedForm = {};
    Object.keys(formValue).forEach((key) => {
      if (key == 'date' && formValue['date']) {
        formatedForm['date'] = this.dateParser.format(formValue['date']);
      } else if (formValue[key]) {
        formatedForm[key] = formValue[key];
      }
    });
    return formatedForm;
  }

  resetForm() {
    this.form.reset();
    this.form.patchValue({ selector: 'ds' });
  }
}
