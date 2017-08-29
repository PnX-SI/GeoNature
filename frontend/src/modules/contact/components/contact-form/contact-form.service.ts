import { Injectable } from '@angular/core';
import { FormControl } from '@angular/forms';

@Injectable()
export class ContactFormService {
  taxon:any;
  indexContact: number;
  inputTaxon: FormControl;
  constructor() {
    this.taxon = {};
    this.indexContact = 0;
    this.inputTaxon = new FormControl();
   }

   updateTaxon(taxon) {
     this.taxon = taxon;
   }

}