import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';

import { Observable, of, Subject, concat } from 'rxjs';
import { distinctUntilChanged, debounceTime, switchMap, tap, catchError } from 'rxjs/operators';

import { DataFormService } from '@geonature_common/form/data-form.service';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';

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
 * de code de noms scientifiques (`cd_nom`). Ces valeurs seront comparés à l'aide
 * de la fonction de l'input `compareWith` aux objets passés dans l'input `defaultItems`.
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
  taxa: Observable<any>;
  taxaInput$ = new Subject<string>();
  loading = false;

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
   * l'affichage (`displayName`), vous pouvez l'indiquer en passant une
   * valeur `null` à cet attribut.
   */
  @Input() valueFieldName: string = 'cd_nom';
  /**
   * Fonction de comparaison entre les élements sélectionnés présent dans
   * le `parentFormControl` et les éléments affichés dans la liste des options.
   * @param item Valeur présente dans la liste d'options.
   * @param selected Valeur présente dans le `FormControl`.
   * @returns
   */
  @Input() compareWith = (item, selected) => item[this.valueFieldName] === selected;
  /**
   * Tableau d'objets qui doivent contenir chacun à minima 2 attributs :
   *  - un attribut correspondant à la valeur de l'input `valueFieldName` et
   * contenant l'"identifiant" du nom scientifique.
   *  - un attribut `displayName` contenant l'intitulé de la zone géographique
   * à afficher.
   * En mise à jour, ces objets doivent correspondres aux id présents dans
   * `parentFormControl`.
   */
  @Input() defaultItems: Array<any> = [];
  /**
   * Permet découter les changements sur la sélection de ng-select.
   * Retourne un tableau d'objets. Les objets correspondent aux items
   * sélectionnés. Chaque objet contient à minima 2 attributs : un
   * correspondant à l'input `valueFieldName`, l'autre est `displayName`.
   */
  @Output() onSelectionChange = new EventEmitter<any>();

  constructor(private dataService: DataFormService) {
    super();
  }

  ngOnInit() {
    this.getTaxa();
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
        switchMap((term) => {
          return term && term.length >= 2
            ? this.dataService.getHigherTaxa(this.rank, term).pipe(
                catchError(() => of([])), // empty list on error
                tap(() => (this.loading = false))
              )
            : of([]);
        }),
        tap(() => (this.loading = false))
      )
    );
  }
}
