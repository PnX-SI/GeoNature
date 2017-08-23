import { Component, OnInit } from '@angular/core';
import {FormControl} from '@angular/forms';
import { FormService } from '../service/form.service';

@Component({
  selector: 'app-taxonomy',
  templateUrl: './taxonomy.component.html',
  styleUrls: ['./taxonomy.component.scss']
})
export class TaxonomyComponent implements OnInit {
  stateCtrl: FormControl;
  filteredTaxons: any;
  constructor(private _formService: FormService) {
        this.stateCtrl = new FormControl();
    this.filteredTaxons = this.stateCtrl.valueChanges
        .startWith(null)
        .map(name => this.filterTaxons(name));
   }

  ngOnInit() {
  }

  filterTaxons(val: string) {
    return val ? this._formService.getTaxonomy().filter(s => s.taxonName.toLowerCase().indexOf(val.toLowerCase()) === 0)
              : null;
  }

}
