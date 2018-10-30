import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation } from '@angular/core';
import { FormControl } from '@angular/forms';
import { Observable } from 'rxjs/Observable';
import { DataFormService } from '../data-form.service';
import { NgbTypeaheadSelectItemEvent } from '@ng-bootstrap/ng-bootstrap';
import { error } from 'util';
import { of } from 'rxjs/observable/of';
import { CommonService } from '@geonature_common/service/common.service';
import { AppConfig } from '@geonature_config/app.config';

export interface Taxon {
  search_name: string;
  nom_valide: string;
  group2_inpn: string;
  regne: string;
  lb_nom: string;
  cd_nom: number;
  cd_ref?: number;
  cd_sup?: number;
  cd_taxsup?: number;
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
  // api endpoint for the automplete ressource
  @Input() apiEndPoint: string;
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
  @Output() onChange = new EventEmitter<NgbTypeaheadSelectItemEvent>(); // renvoie l'evenement, le taxon est récupérable grâce à e.item
  @Output() onDelete = new EventEmitter<Taxon>();

  constructor(private _dfService: DataFormService, private _commonService: CommonService) {}

  ngOnInit() {
    this.parentFormControl.valueChanges
      .filter(value => value !== null && value.length === 0)
      .subscribe(value => {
        this.onDelete.emit();
        this.showResultList = false;
      });
    // set default to apiEndPoint for retrocompatibility
    this.apiEndPoint =
      this.apiEndPoint || `${AppConfig.API_TAXHUB}/taxref/allnamebylist/${this.idList}`;
    // get regne and group2
    this._dfService.getRegneAndGroup2Inpn().subscribe(data => {
      this.regnesAndGroup = data;
      for (let regne in data) {
        this.regnes.push(regne);
      }
    });

    // put group to null if regne = null
    this.regneControl.valueChanges.subscribe(value => {
      if (value === '') {
        this.groupControl.patchValue(null);
      }
    });
  }

  taxonSelected(e: NgbTypeaheadSelectItemEvent) {
    this.onChange.emit(e);
  }

  formatter(taxon) {
    return taxon.nom_valide;
  }

  searchTaxon = (text$: Observable<string>) =>
    text$
      .do(search_name => (this.isLoading = true))
      .debounceTime(400)
      .distinctUntilChanged()
      .switchMap(search_name => {
        if (search_name.length >= this.charNumber && search_name.length <= 20) {
          return this._dfService
            .autocompleteTaxon(this.apiEndPoint, search_name, {
              regne: this.regneControl.value,
              group2_inpn: this.groupControl.value
            })
            .catch(err => {
              if (err.status_code === 500) {
                this._commonService.translateToaster('error', 'ErrorMessage');
              }
              return of([]);
            });
        } else {
          this.isLoading = false;
          return [[]];
        }
      })
      .map(response => {
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
