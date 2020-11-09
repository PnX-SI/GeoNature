import { Injectable } from '@angular/core';
import { FormGroup, FormBuilder } from '@angular/forms';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { keyValuesToMap } from '@angular/flex-layout/extended/typings/style/style-transforms';


@Injectable()
export class MetadataSearchFormService {
    public form: FormGroup
    constructor(private _fb: FormBuilder, public dateParser: NgbDateParserFormatter) {

        this.form = this._fb.group({
            'selector': "ds",
            'uuid': null,
            'name': null,
            'date': null,
            'organism': null,
            'person': null
        })
    }

    formatFormValue(formValue) {
        const formatedForm = {}
        formValue['date'] = this.dateParser.format(formValue['date']);
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