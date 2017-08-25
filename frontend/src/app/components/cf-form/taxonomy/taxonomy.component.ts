import { Component, OnInit } from '@angular/core';
import {FormControl} from '@angular/forms';
import { FormService } from '../service/form.service';
import 'rxjs/add/operator/delay';

@Component({
  selector: 'app-taxonomy',
  templateUrl: './taxonomy.component.html',
  styleUrls: ['./taxonomy.component.scss']
})
export class TaxonomyComponent implements OnInit {
  stateCtrl: FormControl;
  searchString: any;
  filteredTaxons: any;
  constructor(private _formService: FormService) {
      this.stateCtrl = new FormControl();
      this.filteredTaxons = this.stateCtrl.valueChanges
      .startWith(null)
      .map(searchString => this._formService.searchTaxonomy(searchString,'1001')
                           .subscribe(
                              res => this.searchString = res.filter(s => s.search_name.toLowerCase().indexOf(searchString.toLowerCase()) === 0)
                           )).delay(300)
      .map(res => this.searchString)
   }

  ngOnInit() {
  }


}
