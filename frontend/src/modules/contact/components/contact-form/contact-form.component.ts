import { Component, OnInit } from '@angular/core';
import { FormControl, FormGroup, FormArray } from '@angular/forms';
import { DataFormService } from '../../../../core/GN2Common/form/data-form.service';
import { FormService }  from '../../../../core/GN2Common/form/form.service'
import 'rxjs/add/operator/startWith';
import 'rxjs/add/operator/map';



@Component({
  selector: 'pnx-contact-form',
  templateUrl: './contact-form.component.html',
  styleUrls: ['./contact-form.component.scss'],
  providers: [FormService]
})
export class ContactFormComponent implements OnInit {
  dataForm: any;
  dataSets: any;
  taxonsList: Array<any>;
  observationForm:FormGroup;
  occurrenceForm:FormGroup;
  countingForm: FormArray;

  contactForm: FormGroup;
  constructor(private _dfService: DataFormService, public fs: FormService) {  }

  ngOnInit() {
    // releve get dataSet
    this._dfService.getDatasets()
      .subscribe(res => this.dataSets = res);
    // provisoire:
    this.dataSets = [1, 2, 3];

    // init the formsGroups
    this.observationForm = this.fs.initObservationForm();
    this.occurrenceForm = this.fs.initOccurrenceForm();
    this.countingForm = this.fs.initCountingArray();
    
    // init the taxons list
    this.taxonsList = [];

  }

  addOccurence(){
    // add an occurrence
    this.fs.addOccurence(this.occurrenceForm, this.observationForm, this.countingForm);
    // reset the occurence
    this.occurrenceForm = this.fs.initOccurrenceForm();
    //reset the counting
    this.countingForm = this.fs.initCountingArray()

    // push the current taxon in the taxon list and refresh the currentTaxon
    this.taxonsList.push(this.fs.currentTaxon);
    this.fs.currentTaxon = {};
  }

  submitData() {
    this.observationForm = this.fs.initObservationForm();
    this.occurrenceForm = this.fs.initOccurrenceForm();
    this.countingForm = this.fs.initCountingArray();
  }

}
