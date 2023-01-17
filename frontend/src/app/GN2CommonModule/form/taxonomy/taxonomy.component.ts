import {
  Component,
  EventEmitter,
  Input,
  OnChanges,
  OnInit,
  Output,
  ViewEncapsulation,
} from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { CommonService } from '@geonature_common/service/common.service';
import { AppConfig } from '@geonature_config/app.config';
import { NgbTypeaheadSelectItemEvent } from '@ng-bootstrap/ng-bootstrap';
import { Observable, of } from 'rxjs';
import { debounceTime, distinctUntilChanged, filter, map, switchMap, tap } from 'rxjs/operators';
import { DataFormService } from '../data-form.service';

export interface Taxon {
  search_name?: string;
  nom_valide?: string;
  group2_inpn?: string;
  regne?: string;
  lb_nom?: string;
  cd_nom?: number;
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
  statuts_protection?: any[];
  synonymes?: any[];
}

/**
 * Ce composant permet de créer un "input" de type "typeahead" pour rechercher des taxons à partir d'une liste définit dans schéma taxonomie. Table ``taxonomie.bib_listes`` et ``taxonomie.cor_nom_listes``.
 *
 *  @example
 * <pnx-taxonomy #taxon
 * label="{{ 'Taxon.Taxon' | translate }}
 * [parentFormControl]="occurrenceForm.controls.cd_nom"
 * [idList]="occtaxConfig.id_taxon_list"
 * [charNumber]="3"
 *  [listLength]="occtaxConfig.taxon_result_number"
 * (onChange)="fs.onTaxonChanged($event);"
 * [displayAdvancedFilters]=true>
 * </pnx-taxonomy>
 *
 * */
@Component({
  selector: 'pnx-taxonomy',
  templateUrl: './taxonomy.component.html',
  styleUrls: ['./taxonomy.component.scss'],
  encapsulation: ViewEncapsulation.None,
})
export class TaxonomyComponent implements OnInit, OnChanges {
  /**
   * Reactive form
   */
  @Input() parentFormControl: UntypedFormControl;
  @Input() label: string;
  // api endpoint for the automplete ressource
  @Input() apiEndPoint: string;
  /*** Id de la liste de taxon */
  @Input() idList: string;
  /** Nombre de charactere avant que la recherche AJAX soit lançé (obligatoire) */
  @Input() charNumber: number;
  // **ombre de résultat affiché */
  @Input() listLength = 20;
  // ** Pour changer la valeur affichée */
  @Input() displayedLabel = 'nom_valide';
  /** Afficher ou non les filtres par regne et groupe INPN qui controle l'autocomplétion */
  @Input() displayAdvancedFilters = false;
  searchString: any;
  filteredTaxons: any;
  regnes = new Array();
  regneControl = new UntypedFormControl(null);
  groupControl = new UntypedFormControl(null);
  regnesAndGroup: any;
  noResult: boolean;
  isLoading = false;
  @Output() onChange = new EventEmitter<NgbTypeaheadSelectItemEvent>(); // renvoie l'evenement, le taxon est récupérable grâce à e.item
  @Output() onDelete = new EventEmitter<Taxon>();

  constructor(private _dfService: DataFormService, private _commonService: CommonService) {}

  ngOnInit() {
    if (!this.apiEndPoint) {
      this.setApiEndPoint(this.idList);
    }
    this.parentFormControl.valueChanges
      .pipe(filter((value) => value !== null && value.length === 0))
      .subscribe((value) => {
        this.onDelete.emit();
      });
    if (this.displayAdvancedFilters) {
      // get regne and group2
      this._dfService.getRegneAndGroup2Inpn().subscribe((data) => {
        this.regnesAndGroup = data;
        for (const regne in data) {
          this.regnes.push(regne);
        }
      });
    }

    // put group to null if regne = null
    this.regneControl.valueChanges.subscribe((value) => {
      if (value === '') {
        this.groupControl.patchValue(null);
      }
    });
  }

  ngOnChanges(changes) {
    if (changes && changes.idList) {
      this.setApiEndPoint(changes.idList.currentValue);
    }
  }

  setApiEndPoint(idList) {
    if (idList) {
      this.apiEndPoint = `${AppConfig.API_TAXHUB}/taxref/allnamebylist/${idList}`;
    } else {
      this.apiEndPoint = `${AppConfig.API_TAXHUB}/taxref/allnamebylist`;
    }
  }

  taxonSelected(e: NgbTypeaheadSelectItemEvent) {
    this.onChange.emit(e);
  }

  formatter = (taxon: any) => {
    return taxon[this.displayedLabel].replace(/<[^>]*>/g, ''); // supprime les balises HTML
  };

  searchTaxon = (text$: Observable<string>) =>
    text$.pipe(
      distinctUntilChanged(),
      debounceTime(400),
      tap(() => (this.isLoading = true)),
      switchMap((search_name_) => {
        const search_name = search_name_.toString();
        if (search_name.length >= this.charNumber) {
          return this._dfService
            .autocompleteTaxon(this.apiEndPoint, search_name, {
              regne: this.regneControl.value,
              group2_inpn: this.groupControl.value,
              limit: this.listLength.toString(),
            })
            .catch(() => {
              return of([]);
            });
        } else {
          this.isLoading = false;
          return [[]];
        }
      }),
      map((response) => {
        this.noResult = response.length === 0;
        this.isLoading = false;
        return response;
      })
    );

  refreshAllInput() {
    this.parentFormControl.reset();
    this.regneControl.reset();
    this.groupControl.reset();
  }
}
