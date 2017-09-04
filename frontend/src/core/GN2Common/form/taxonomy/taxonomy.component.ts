import { Component, OnInit, Input, Output, EventEmitter, OnChanges } from '@angular/core';
import {FormControl} from '@angular/forms';
import { DataFormService } from '../data-form.service';

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
  constructor(private _dfService: DataFormService) {}

  ngOnInit() {
    this.autocompleteTaxons(3, 20);
  }

  displaySearchName(taxon): string {
    return taxon ? taxon.nom_valide : '';
  }

  ngOnChanges(changes){
    // if the formcontroller change, we have to reload the observable
    if(changes.inputTaxon){
      this.autocompleteTaxons(3, 20);
    }
  }

  autocompleteTaxons (keyoardNumber, listLength){
    this.inputTaxon.valueChanges
    .filter(value => (value.length >= keyoardNumber && value.length <= 20))
    .debounceTime(400)
    .distinctUntilChanged()
    .switchMap(value => this._dfService.searchTaxonomy(value, '1001'))
      .subscribe(response => this.taxons = response.slice(0, listLength));
  }
  
  onTaxonSelected(taxon){    
    this.taxonChanged.emit(taxon);
  }

}
