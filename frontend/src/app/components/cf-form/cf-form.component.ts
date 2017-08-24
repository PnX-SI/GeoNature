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
  nbCounting: Array<any>;
  countings: Array<Counting>;
  stateCtrl: FormControl;
  dataForm: any;
  constructor() {  }
  ngOnInit() {
    this.nbCounting = [''];
    this.dataForm = {
      observers : [],
      countings: [new Counting()]
    };
  }

  // Observer component
  addObservers(observer) {
    this.dataForm.observers.push(observer);
  }

  deleteObservers(observer) {
    const index = this.dataForm.observers.indexOf(observer);
    this.dataForm.observers.split(index, 1);
  }

  // nomenclature component
  updateModelWithLabel(nomclatureObj) {
    const nomenclatureName = nomclatureObj.nomenclature.toLowerCase();
    const idLabel = nomclatureObj.idLabel;
    this.dataForm[nomenclatureName] = idLabel;
  }

  // counting component
  updateCountingModel(countingInput) {
    // update the current changed Input
    const nomenclatureName = countingInput.nomenclatureObj.nomenclature.toLowerCase();
    const idLabel = countingInput.nomenclatureObj.idLabel;
    this.dataForm.countings[countingInput.index][nomenclatureName] = idLabel;
  }
  addCounting() {
    // add a new counting component in the form
    this.dataForm.countings.push(new Counting());
    this.nbCounting.push('');
  }
}
