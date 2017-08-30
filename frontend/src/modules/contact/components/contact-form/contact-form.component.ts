import { Component, OnInit } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { CountingComponent } from '../counting/counting.component';
import { Counting } from '../counting/counting.type';
import { FormService } from '../../../../core/GN2Common/form/form.service';
import { ContactFormService }  from './contact-form.service'
import 'rxjs/add/operator/startWith';
import 'rxjs/add/operator/map';



@Component({
  selector: 'pnx-contact-form',
  templateUrl: './contact-form.component.html',
  styleUrls: ['./contact-form.component.scss']
})
export class ContactFormComponent implements OnInit {
  dataForm: any;
  dataSets: any;

  contactForm: FormGroup;
  constructor(private _formService: FormService, public cfs: ContactFormService) {  }

  ngOnInit() {
    // releve get dataSet
    this._formService.getDatasets()
      .subscribe(res => this.dataSets = res);
    // provisoire:
    this.dataSets = [1, 2, 3];
  }

  submitData() {
    console.log(this.cfs.contactForm.value)
  }

}
