import { Component, OnInit } from '@angular/core';
import { FormGroup, FormArray } from '@angular/forms';
import { FormService }  from '../../../../core/GN2Common/form/form.service'
import { MapService } from '../../../../core/GN2Common/map/map.service';


@Component({
  selector: 'pnx-contact-form',
  templateUrl: './contact-form.component.html',
  styleUrls: ['./contact-form.component.scss'],
  providers: [FormService]
})
export class ContactFormComponent implements OnInit {
  public taxonsList: Array<any>;
  public releveForm:FormGroup;
  public occurrenceForm:FormGroup;
  public countingForm: FormArray;
  public contactForm: FormGroup;

  constructor(public fs: FormService, private _ms: MapService) {  }

  ngOnInit() {
    // init the formsGroups
    this.releveForm = this.fs.initObservationForm();
    this.occurrenceForm = this.fs.initOccurrenceForm();
    this.countingForm = this.fs.initCountingArray();
    // init the taxons list
    this.taxonsList = [];
  }

  addOccurence(){
    // add an occurrence
    this.fs.addOccurence(this.occurrenceForm, this.releveForm, this.countingForm);
    // reset the occurence
    this.occurrenceForm = this.fs.initOccurrenceForm();
    //reset the counting
    this.countingForm = this.fs.initCountingArray()

    // push the current taxon in the taxon list and refresh the currentTaxon
    this.taxonsList.push(this.fs.currentTaxon);
    this.fs.currentTaxon = {};
  }

  submitData() {
    // resert the forms
    this.releveForm = this.fs.initObservationForm();
    this.occurrenceForm = this.fs.initOccurrenceForm();
    this.countingForm = this.fs.initCountingArray();
  }


}
