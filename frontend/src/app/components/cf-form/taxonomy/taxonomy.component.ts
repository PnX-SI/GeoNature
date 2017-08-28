import { Component, OnInit } from '@angular/core';
import {FormControl} from '@angular/forms';
import { FormService } from '../service/form.service';

@Component({
  selector: 'app-taxonomy',
  templateUrl: './taxonomy.component.html',
  styleUrls: ['./taxonomy.component.scss']
})
export class TaxonomyComponent implements OnInit {
  inputTaxon: FormControl;
  taxonsList: Array<any>;
  searchString: any;
  filteredTaxons: any;
  constructor(private _formService: FormService) {}

  ngOnInit() {
    this.inputTaxon = new FormControl();

    this.inputTaxon.valueChanges
      .filter(value => (value.length >= 3 && value.length <= 20))
      .debounceTime(400)
      .distinctUntilChanged()
      .switchMap(value => this._formService.searchTaxonomy(value, '1001'))
        .subscribe(response => this.taxonsList = response);
  }

  getTaxonInfo(taxon) {
    this._formService.taxon = taxon;
  }

}
