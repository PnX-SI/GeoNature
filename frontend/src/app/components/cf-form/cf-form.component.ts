import { Component, OnInit } from '@angular/core';
import {FormControl} from '@angular/forms';
import {NomenclatureComponent} from './nomenclature/nomenclature.component';
import { CountingComponent } from './counting/counting.component';
import { Counting } from './counting/counting.type';
import 'rxjs/add/operator/startWith';
import 'rxjs/add/operator/map';



@Component({
  selector: 'app-cf-form',
  templateUrl: './cf-form.component.html',
  styleUrls: ['./cf-form.component.scss']
})
export class CfFormComponent implements OnInit {
  nbCounting: Array<string>;
  observationContact: any;
  occurenceContact: Array<any>;
  countingsContact: Array<any>;
  stateCtrl: FormControl;
  dataForm: any;
  constructor() {  }

  ngOnInit() {
    this.observationContact = {'observers': []};
    this.occurenceContact = [{}];
    this.countingsContact = [{}];
    this.nbCounting = [''];
    this.dataForm = {
      geometry: {
        type: '',
        coordinates: []
      },
      properties: {
      observers : [],
      t_occurrences_contact: [{
        cor_counting_contact: []
      }]
      }
    };
  }// end ngOnInit

  // Observer component
  addObservers(observer) {
    this.observationContact.observers.push(observer);
  }

  deleteObservers(observer) {
    const index = this.dataForm.observers.indexOf(observer);
    this.dataForm.properties.observers.splice(index, 1);
  }

  // nomenclature component
  updateOccurenceContact(idLabel, fieldName) {
    this.occurenceContact[0][fieldName] = idLabel;
  }

  // counting component
  updateCountingContact(countingInput) {
    const index = countingInput.index;
    const fieldName = countingInput.key;
    const idLabel = countingInput.value;
    this.countingsContact[index][fieldName] = idLabel;
  }
  addCounting() {
    // add a new counting component in the form
    this.countingsContact.push(new Counting());
    this.nbCounting.push('');
  }
  removeCounting(index) {
    // remove the indexed component in the form
    this.countingsContact.splice(index, 1);
    this.nbCounting.splice(index, 1);
  }

}
