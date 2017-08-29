import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import {FormControl} from '@angular/forms';
import { FormService } from '../form.service';

@Component({
  selector: 'pnx-taxonomy',
  templateUrl: './taxonomy.component.html',
  styleUrls: ['./taxonomy.component.scss']
})
export class TaxonomyComponent implements OnInit {
  @Input() inputTaxon: FormControl;
  taxonsList: Array<any>;
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
        .subscribe(response => this.taxonsList = response);
  }

  // getTaxonInfo(taxon) {
  //   this._formService.taxon = taxon;
  // }

  onTaxonSelected(taxon){
    this.taxonChanged.emit(taxon);
  }

}
