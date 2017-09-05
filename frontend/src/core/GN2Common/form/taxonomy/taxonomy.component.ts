import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import {FormControl} from '@angular/forms';
import {Observable} from 'rxjs/Observable';
import { DataFormService } from '../data-form.service';
import { NgbTypeaheadSelectItemEvent } from '@ng-bootstrap/ng-bootstrap';


@Component({
  selector: 'pnx-taxonomy',
  templateUrl: './taxonomy.component.html',
  styleUrls: ['./taxonomy.component.scss']
})
export class TaxonomyComponent implements OnInit {
  @Input('parentFormControl') inputTaxon: FormControl;
  @Input() idList: string;
  @Input() charNumber:number;
  @Input() listLength:number;
  taxons: Array<any>;
  searchString: any;
  filteredTaxons: any;

  @Output() taxonChanged = new EventEmitter<any>();
  constructor(private _dfService: DataFormService) {}

  ngOnInit() {
  }

  taxonSelected(e:NgbTypeaheadSelectItemEvent){
    this.taxonChanged.emit(e.item)
    this.inputTaxon.setValue(e.item.cd_nom);    
  }

  formatter(taxon){
    return taxon.nom_valide;
  }

  searchTaxon = (text$: Observable<string>) =>
    text$
      .filter(value => (value.length >= this.charNumber && value.length <= 20))
      .debounceTime(400)
      .distinctUntilChanged()
      .switchMap(value => this._dfService.searchTaxonomy(value, this.idList))
        .map(response => response.slice(0, this.listLength))
      
}
