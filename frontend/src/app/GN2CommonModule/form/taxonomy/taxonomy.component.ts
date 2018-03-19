import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation } from '@angular/core';
import { FormControl } from '@angular/forms';
import { Observable } from 'rxjs/Observable';
import { DataFormService } from '../data-form.service';
import { NgbTypeaheadSelectItemEvent } from '@ng-bootstrap/ng-bootstrap';
import { error } from 'util';
import { of } from 'rxjs/observable/of';
import { CommonService } from '@geonature_common/service/common.service';

export interface Taxon {
  search_name: string;
  nom_valide: string;
  group2_inpn: string;
  regne: string;
  lb_nom: string;
  cd_nom: number;
  cd_ref?: number;
  cd_sup?: number;
  cd_taxsup?: 189946;
  classe?: string;
  famille?: string;
  group1_inpn?: string;
  id_rang?: string;
  nom_complet?: string;
  nom_habitat?: string;
  nom_rang?: string;
  nom_statut?: string;
  nom_vern?: string;
  ordre?: string;
  phylum?: string;
  statuts_protection?: Array<any>;
  synonymes?: Array<any>;
}

@Component({
  selector: 'pnx-taxonomy',
  templateUrl: './taxonomy.component.html',
  styleUrls: ['./taxonomy.component.scss'],
  encapsulation: ViewEncapsulation.None
})
export class TaxonomyComponent implements OnInit {
  @Input() parentFormControl: FormControl;
  @Input() label: string;
  @Input() idList: string;
  @Input() charNumber: number;
  @Input() listLength: number;
  @Input() refresh: Function;
  searchString: any;
  filteredTaxons: any;
  regnes = new Array();
  regneControl = new FormControl(null);
  groupControl = new FormControl(null);
  regnesAndGroup: any;
  noResult: boolean;
  isLoading = false;
  showResultList = true;
  @Output() onChange = new EventEmitter<Taxon>();
  @Output() onDelete = new EventEmitter<Taxon>();

  constructor(private _dfService: DataFormService, private _commonService: CommonService) {}

  ngOnInit() {
    this.parentFormControl.valueChanges
      .filter(value => value !== null && value.length === 0)
      .subscribe(value => {
        this.onDelete.emit();
        this.showResultList = false;
      });
    // get regne and group2
    this._dfService.getRegneAndGroup2Inpn().subscribe(data => {
      this.regnesAndGroup = data;
      for (let regne in data) {
        this.regnes.push(regne);
      }
    });

    const test: Taxon = {
      search_name: 'lalal',
      nom_valide: 'lol',
      group2_inpn: 'string',
      regne: 'string',
      lb_nom: 'string',
      cd_nom: 15
    };

    // put group to null if regne = null
    this.regneControl.valueChanges.subscribe(value => {
      if (value === '') {
        this.groupControl.patchValue(null);
      }
    });
  }

  taxonSelected(e: NgbTypeaheadSelectItemEvent) {
    this.onChange.emit(e.item);
  }

  formatter(taxon) {
    return taxon.nom_valide;
  }

  searchTaxon = (text$: Observable<string>) =>
    text$
      .do(value => (this.isLoading = true))
      .debounceTime(400)
      .distinctUntilChanged()
      .switchMap(value => {
        if (value.length >= this.charNumber && value.length <= 20) {
          return this._dfService
            .searchTaxonomy(value, this.idList, this.regneControl.value, this.groupControl.value)
            .catch(err => {
              this._commonService.translateToaster('error', 'ErrorMessage');
              return of([]);
            });
        } else {
          this.isLoading = false;
          return [[]];
        }
      })
      .map(response => {
        console.log(response);
        this.noResult = response.length === 0;
        this.isLoading = false;
        return response.slice(0, this.listLength);
      });

  refreshAllInput() {
    this.parentFormControl.reset();
    this.regneControl.reset();
    this.groupControl.reset();
  }
}
