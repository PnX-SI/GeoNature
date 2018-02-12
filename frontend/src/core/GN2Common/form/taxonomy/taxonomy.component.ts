import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation } from '@angular/core';
import {FormControl} from '@angular/forms';
import {Observable} from 'rxjs/Observable';
import { DataFormService } from '../data-form.service';
import { NgbTypeaheadSelectItemEvent } from '@ng-bootstrap/ng-bootstrap';


@Component({
  selector: 'pnx-taxonomy',
  templateUrl: './taxonomy.component.html',
  styleUrls: ['./taxonomy.component.scss'],
  encapsulation: ViewEncapsulation.None,
})
export class TaxonomyComponent implements OnInit {
  @Input() parentFormControl: FormControl;
  @Input() idList: string;
  @Input() charNumber: number;
  @Input() listLength: number;
  @Input() refresh: Function;
  taxons: Array<any>;
  searchString: any;
  filteredTaxons: any;
  regnes = new Array();
  regneControl = new FormControl(null);
  groupControl = new FormControl(null);
  regnesAndGroup: any;
  noResult: boolean;
  showSpinner = false;
  @Output() taxonChanged = new EventEmitter<any>();
  @Output() taxonDeleted = new EventEmitter<any>();

  constructor(
    private _dfService: DataFormService
  ) {}

  ngOnInit() {
    this.parentFormControl.valueChanges
      .filter(value => value !== null && value.length === 0)
      .subscribe(value => {
        this.taxonDeleted.emit();
      });
    // get regne and group2
    this._dfService.getRegneAndGroup2Inpn()
    .subscribe(data => {
      this.regnesAndGroup = data;
      for (let regne in data) {
        this.regnes.push(regne);
      }
    })

    // put group to null if regne = null
    this.regneControl.valueChanges
      .subscribe(value => {
        if (value === '') {
          this.groupControl.patchValue(null);
        }
      });
  }

  taxonSelected(e: NgbTypeaheadSelectItemEvent) {
    this.taxonChanged.emit(e.item);
  }

  formatter(taxon) {
    return taxon.nom_valide;
  }

  searchTaxon = (text$: Observable<string>) =>
    text$
      .filter(value => (value.length >= this.charNumber && value.length <= 20))
      .debounceTime(400)
      .distinctUntilChanged()
      .do(() => this.showSpinner = true)
      .switchMap(value => this._dfService.searchTaxonomy(
        value, this.idList, this.regneControl.value, this.groupControl.value)
      )
        .map(response => {
          this.noResult = response.length === 0 ;
          this.showSpinner = false;
          return response.slice(0, this.listLength);
        })

  refreshAllInput() {
    console.log('alalalalla');
    
    this.parentFormControl.reset();
    this.regneControl.reset();
    this.groupControl.reset();
  }


}
