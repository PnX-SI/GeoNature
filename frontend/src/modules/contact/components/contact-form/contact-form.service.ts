import { Injectable } from '@angular/core';

@Injectable()
export class ContactFormService {
  taxon:any;
  indexContact: number;
  constructor() {
    this.taxon = {};
    this.indexContact = 0;
   }

   updateTaxon(taxon) {
     this.taxon = taxon;
   }
}