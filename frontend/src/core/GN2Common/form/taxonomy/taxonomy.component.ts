import { Component, OnInit, Input, Output, EventEmitter, OnChanges } from '@angular/core';
import {FormControl} from '@angular/forms';
import { FormService } from '../form.service';

@Component({
  selector: 'pnx-taxonomy',
  templateUrl: './taxonomy.component.html',
  styleUrls: ['./taxonomy.component.scss']
})
export class TaxonomyComponent implements OnInit, OnChanges {
  @Input('parentFormControl') inputTaxon: FormControl;
  taxons: Array<any>;
  searchString: any;
  filteredTaxons: any;
  @Output() taxonChanged = new EventEmitter<any>();
  constructor(private _formService: FormService) {}

  ngOnInit() {
    this.inputTaxon.valueChanges
      .filter(value => (value.length >= 3 && value.length <= 20))
      .debounceTime(400)
      .distinctUntilChanged()
      .switchMap(value => this._formService.searchTaxonomy(value, '1001'))
        .subscribe(response => this.taxons = response);
    this.taxons = [];
    this.inputTaxon.valueChanges.subscribe(value=>{
      console.log(value);
    })
  }

  displaySearchName(taxon): string {
    return taxon ? taxon.search_name : '';
  }

  ngOnChanges(changes){
    // if the formcontroller change, we have to reload the observable
    if(changes.inputTaxon){
      this.inputTaxon.valueChanges
      .filter(value => (value.length >= 3 && value.length <= 20))
      .debounceTime(400)
      .distinctUntilChanged()
      .switchMap(value => this._formService.searchTaxonomy(value, '1001'))
        .subscribe(response => this.taxons = response);
    }
  }
  



  onTaxonSelected(taxon){    
    this.taxonChanged.emit(taxon);
  }

}
