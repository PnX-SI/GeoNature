import { Component, OnInit } from '@angular/core';
import {FormControl} from '@angular/forms';
import {NomenclatureComponent} from './nomenclature/nomenclature.component';
import { CountingComponent } from './counting/counting.component';
import { Counting } from './counting/counting.type';
import { FormService } from './service/form.service';
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
  dataSets: any;
  taxonList: Array<any>;
  constructor(public formService: FormService) {  }

  ngOnInit() {
    this.observationContact = {'observers': []};
    this.occurenceContact = [{}];
    this.countingsContact = [{}];
    this.nbCounting = [''];
    this.taxonList = [];
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
    // releve get dataSet
    this.formService.getDatasets()
      .then(res => {this.dataSets = res; });
    // provisoire:
    this.dataSets = [1, 2, 3];
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

  // taxonList component
  addCurrentTaxon() {
    const currentTaxon = this.formService.taxon;
    // add to the taxon-list component
    this.taxonList.push(currentTaxon);
    // add into occurence contact dict
    this.occurenceContact.push({});
    this.occurenceContact[this.formService.indexContact].nom_cite = currentTaxon.nom_cite;
    this.occurenceContact[this.formService.indexContact].cd_nom = currentTaxon.cd_nom;
    // add the coutings into occurence contact dict
    this.occurenceContact[this.formService.indexContact]['cor_counting_contact'] = this.countingsContact;
    // clear counting contact
    this.countingsContact = [{}];
    this.nbCounting = [''];
    // clear the current taxon
    this.formService.taxon = {};
    // update the index of the current contact
    this.formService.indexContact += 1;
  }

  removeOneOccurenceTaxon(index): void {
    this.occurenceContact.splice(index, 1);
  }

}
