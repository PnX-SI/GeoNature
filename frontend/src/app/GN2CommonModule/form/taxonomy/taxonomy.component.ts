import {
  Component,
  EventEmitter,
  Input,
  OnChanges,
  OnInit,
  Output,
  ViewChild,
} from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { NgbTypeaheadSelectItemEvent } from '@ng-bootstrap/ng-bootstrap';
import { DataFormService } from '../data-form.service';
import { ConfigService } from '@geonature/services/config.service';
import { TaxonomySelectComponent, TaxonSearchFilters } from './taxonomy-select.component';
import { taxonSearchEndPoint } from './taxonomy.utils';

export interface TaxonParent {
  cd_ref: number;
  lb_nom: string;
  id_rang: string;
}

export type TaxonParents = Array<TaxonParent>;

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
  status?: any[];
  synonymes?: any[];
  attributs?: any[];
}

/**
 * Ce composant (connecté à l'API TaxHub, la partie affichage est dans ``pnx-taxonomy-select``) permet de créer un "input" de type "typeahead" pour rechercher des taxons à partir d'une liste définit dans schéma taxonomie. Table ``taxonomie.bib_listes`` et ``taxonomie.cor_nom_listes``.
 *
 *  @example
 * <pnx-taxonomy #taxon
 * label="{{ 'Taxon' | translate }}
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
  regnesAndGroup: any;
  @Output() onChange = new EventEmitter<NgbTypeaheadSelectItemEvent>(); // renvoie l'evenement, le taxon est récupérable grâce à e.item
  @Output() onDelete = new EventEmitter<Taxon>();
  @ViewChild(TaxonomySelectComponent) private _select?: TaxonomySelectComponent;

  constructor(
    private _dfService: DataFormService,
    public config: ConfigService
  ) {}

  ngOnInit() {
    if (!this.apiEndPoint) {
      this.setApiEndPoint(this.idList);
    }
    if (this.displayAdvancedFilters) {
      // get regne and group2
      this._dfService.getRegneAndGroup2Inpn().subscribe((data) => {
        this.regnesAndGroup = data;
      });
    }
  }

  ngOnChanges(changes) {
    if (changes && changes.idList) {
      this.setApiEndPoint(changes.idList.currentValue);
    }
  }

  setApiEndPoint(idList) {
    this.apiEndPoint = taxonSearchEndPoint(this._dfService.getTaxhubAPI(), idList);
  }

  /** Search the taxa matching a term in the TaxHub API */
  searchFn = (term: string, filters: TaxonSearchFilters) =>
    this._dfService.autocompleteTaxon(this.apiEndPoint, term, {
      regne: filters.regne,
      group2_inpn: filters.group2_inpn,
      limit: this.listLength.toString(),
    });

  /** Reset the search input and the regne and group filters */
  refreshAllInput() {
    if (this._select) {
      this._select.refreshAllInput();
    } else {
      this.parentFormControl.reset();
    }
  }
}
