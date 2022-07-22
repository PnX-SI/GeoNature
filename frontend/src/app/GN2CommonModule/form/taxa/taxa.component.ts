import { Component, OnInit, Input } from '@angular/core';

import { Observable, of, Subject, concat } from 'rxjs';
import {
  distinctUntilChanged,
  debounceTime,
  switchMap,
  tap,
  catchError,
} from 'rxjs/operators';

import { DataFormService } from '@geonature_common/form/data-form.service';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { CommonService } from '@geonature_common/service/common.service';


/**
 * Ce composant a le même comportement que {@link AreasComponent|pnx-areas}.
 *
 * Il encapsule ng-select et utilise un observable contenant une liste de
 * noms scientifiques supérieurs à un rang donné (`rank`).
 *
 * La liste de noms scientifiques correspond aux caractères tapés dans la
 * zone de recherche. L'affichage de la liste ne se déclenche qu'à partir de la
 * saisie du second caractères. Au maximum 20 noms sont affichés.
 *
 * Ce composant retourne une liste de code de noms scientifiques (`cd_nom`)
 * dans la variable `parentFormControl` correspondant aux sélections de l'utilisateur.
 *
 * En mode mise à jour, il est nécessaire de fournir dans `parentFormControl` une liste
 * d'objets. Ces objets doivent contenir à minima 2 attributs :
 *  - un attribut correspondant à la valeur de l'input `valueFieldName` et
 * contenant l'"identifiant" d'un nom.
 *  - un attribut `displayName` contenant l'intitulé du nom scientifique
 * à afficher.
 * Le composant se charge de transformer le contenu de l'input `parentFormControl`
 * pour qu'il contienne en sortie seulement une liste d'"identifiant" (`valueFieldName`).
 *
 * @example
 * <pnx-taxa
 *   label="Mon libellé de champ"
 *   rank="GN"
 *   [parentFormControl]="form.controls.taxa"
 * >
 * </pnx-taxa>
 */
@Component({
  selector: 'pnx-taxa',
  templateUrl: 'taxa.component.html',
})
export class TaxaComponent extends GenericFormComponent implements OnInit {
  public taxa: any;
  /**
   * Rang minimum des noms recherchés.
   * Utiliser une valeur du champ "`id_rang`" de la table "`bib_taxref_rangs`".
   * Par défaut, le rang défini correspond au Genre (=GN).
   */
  @Input() rank: string = 'GN';
  /**
   * Nom du champ à utiliser pour déterminer la valeur à utiliser pour le
   * contenu du `FormControl`.
   * Si vous souhaitez forcer le maintient dans `parentFormControl` d'un
   * tableau d'objets comprenant le champ identifiant et le champ pour
   * l'affichage (`area_name`), vous pouvez l'indiquer en passant une
   * valeur `null` à cet attribut.
   */
  @Input() valueFieldName: string = 'cd_nom';
  /**
   * Fonction de comparaison entre les élements sélectionnés et les éléments
   * affichés dans la liste des options.
   * @param item Valeur présente dans la liste d'options.
   * @param selected Valeur présente dans le `FormControl`.
   * @returns
   */
  @Input() compareWith = (item, selected) => item[this.valueFieldName] === selected;
  taxaInput$ = new Subject<string>();
  loading = false;
  private defaultItems = [];

  /** @ignore */
  constructor(private dataService: DataFormService, private commonService: CommonService) {
    super()
  }

  ngOnInit() {
    this.updateParentFormControl();
    this.getTaxa();
  }

  private updateParentFormControl() {
    // Replace objects by valueFieldName values
    if (this.parentFormControl.value) {
      this.defaultItems = this.parentFormControl.value;
      this.parentFormControl.setValue(this.defaultItems.map(item => item[this.valueFieldName]));
    }
  }

  /** Relance un appel à l'API fournissant les noms scientifiques si le
   * nombre de caractères saisies dans le zone de recherche est supérieur
   * ou égal à 2.
   */
  getTaxa() {
    this.taxa = concat(
      of(this.defaultItems), // Load items for update mode
      this.taxaInput$.pipe(
        debounceTime(200),
        distinctUntilChanged(),
        tap(() => (this.loading = true)),
        switchMap(term => {
          return term && term.length >= 2
            ? this.dataService.getHigherTaxa(this.rank, term).pipe(
              catchError(() => of([])) // empty list on error
            )
            : of([]);
        }),
        tap(() => (this.loading = false))
      )
    );
  }
   /*
   * La liste de noms est réinitialisée quand un nom est sélectionné ou
   * la zone de recherche vidée.
   *
   * @param taxon_name La chaine de caractère saisie dans la zone de
   * recherche.
   */
  refreshTaxaList(taxon_name) {
    if (taxon_name && taxon_name.length >= 2) {
      this.dataService.getHigherTaxa(this.rank, taxon_name).subscribe(
        (data) => {
          this.taxa = data;
        },
        (err) => {
          if (err.status === 404) {
            this.taxa = [{ displayName: 'No data to display' }];
          } else {
            this.taxa = [];
          }
        }
      );
    } else if (!taxon_name) {
      this.taxa = [];
    }
  }
}
