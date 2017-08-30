import { Injectable } from '@angular/core';
import { FormControl, FormBuilder, FormGroup, FormArray } from '@angular/forms';
import {  } from '@angular/forms';

@Injectable()
export class ContactFormService {
  currentTaxon:any;
  taxonsList: Array<any>;
  indexOccurence:number;
  indexCounting: number;
  nbCounting: Array<string>;
  contactForm: FormGroup;
  countingForm : FormArray;
  constructor(private _fb: FormBuilder) {
    this.currentTaxon = {};
    this.indexOccurence = 0;
    this.indexCounting = 0;
    this.nbCounting = [''];
    this.taxonsList = [];

    // Contact and releve Form
    this.contactForm = this._fb.group({
      observers:'',
      dateMin: '',
      dateMax: '',
      dataSet: '',
      comment: '',
      t_occurrences_contact: this._fb.array([])
      });
    // init occurence contact
    const occurenceControl = <FormArray>this.contactForm.controls['t_occurrences_contact'];
    const newOccurenceCtrl = this.initOccurenceForm();
    occurenceControl.push(newOccurenceCtrl);

    // counting form
    this.countingForm = this.initCountingArray();
    

   }// end constructor

   initOccurenceForm(){
    return this._fb.group({
      id_nomenclature_obs_technique :'',
      id_nomenclature_obs_meth: '',
      id_nomenclature_bio_condition:'',
      id_nomenclature_bio_status :'',
      id_nomenclature_naturalness :'',
      determination_method:'',
      determiner:'',
      digital_proof:'',
      non_digital_proof:'',
      cd_nom:'',
      comment:'',
      cor_counting_contact: ''
    })
  }

   initCounting(): FormGroup {
    return this._fb.group({
      id_nomenclature_life_stage:'',
      id_nomenclature_sex:'',
      id_nomenclature_obj_count: '',
      id_nomenclature_type_count:'',
      count_min :'',
      count_max :''
    })
  }

  initCountingArray():FormArray{
    const arrayForm = this._fb.array([])
    arrayForm.push(this.initCounting());
    return arrayForm
  }

  addOccurence(){
    // add an other occurence
    const control = <FormArray>this.contactForm.controls['t_occurrences_contact'];
    const addCtrl = this.initOccurenceForm();
    control.push(addCtrl);

    // push the counting(s) in cor_counting_contact
    this.contactForm.value.t_occurrences_contact[this.indexOccurence].cor_counting_contact = this.countingForm.value;
     this.indexOccurence += 1;

    // reset counting
     this.nbCounting = [''];
     this.indexCounting = 0;
     this.countingForm = this.initCountingArray();

    // push the current taxon in the taxon list
    this.taxonsList.push(this.currentTaxon);
  }

  removeOneOccurenceTaxon(index){
    this.contactForm.value.t_occurrences_contact.splice(index,1)
  }

  addCounting(){
    this.indexCounting += 1;
    this.nbCounting.push('');
    const countingCtrl = this.initCounting();
    this.countingForm.push(countingCtrl)
    }

   updateTaxon(taxon) {
     this.currentTaxon = taxon;
   }

}