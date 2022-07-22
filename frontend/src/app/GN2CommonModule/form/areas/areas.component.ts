import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';

import { Subject, Observable, of, concat, zip } from 'rxjs';
import {
  distinctUntilChanged,
  debounceTime,
  switchMap,
  tap,
  catchError,
  map,
  distinct,
} from 'rxjs/operators';

import { AppConfig } from '@geonature_config/app.config';
import { DataFormService } from '../data-form.service';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';

/**
 * Ce composant permet de sélectionner une ou plusieurs zones géographiques.
 *
 * Il encapsule ng-select et utilise un observable contenant une liste de
 * zones géographiques qui peuvent être restreint par une liste de types (`typeCodes`).
 *
 * La liste des zones géographiques correspond aux caractères tapés dans la
 * zone de recherche. L'affichage de la liste ne se déclenche qu'à partir de la
 * saisie du second caractères.
 * Par défaut, la liste des 100 premières zones géographiques et pré-chargées.
 *
 * Ce composant retourne une liste d'identifiant de zones géographiques (`id_areas`)
 * dans la variable `parentFormControl` correspondant aux sélections de l'utilisateur.
 *
 * En mode mise à jour, il est nécessaire de fournir dans `parentFormControl` une liste
 * d'objets. Ces objets doivent contenir à minima 2 attributs :
 *  - un attribut correspondant à la valeur de l'input `valueFieldName` et
 * contenant l'identifiant de la zone géographique.
 *  - un attribut `area_name` contenant l'intitulé de la zone géographique
 * à afficher.
 * Le composant se charge de transformer le contenu de l'input `parentFormControl`
 * pour qu'il contienne en sortie seulement une liste d'identifiant.
 *
 * @example
 * <pnx-areas
 *   label="Mon libellé de champ"
 *   [typeCodes]="['COM', 'DEP']"
 *   [parentFormControl]="form.controls.areas"
 * >
 * </pnx-areas>
 */
@Component({
  selector: 'pnx-areas',
  templateUrl: 'areas.component.html',
})
export class AreasComponent extends GenericFormComponent implements OnInit {
  /**
   * Permet de définir une liste de `type_code` à prendre compte.
   * Utiliser une valeur du champ "`type_code`" de la table "`bib_areas_types`".
   * Les zones géographiques affichées dans la liste sont limitées aux
   * `type_code` indiqués dans cet attribut.
   */
  @Input() typeCodes: Array<string> = []; // Areas type_code
  /**
   * Nom du champ à utiliser pour déterminer la valeur à utiliser pour le
   * contenu du `FormControl`.
   * Si vous souhaitez forcer le maintient dans `parentFormControl` d'un
   * tableau d'objets comprenant le champ identifiant et le champ pour
   * l'affichage (`area_name`), vous pouvez l'indiquer en passant une
   * valeur `null` à cet attribut.
   */
  @Input() valueFieldName: string = 'id_area';
  /**
   * Fonction de comparaison entre les élements sélectionnés présent dans
   * le `parentFormControl` et les éléments affichés dans la liste des options.
   * @param item
   * @param selected
   * @returns
   */
  @Input() compareWith = (item, selected) => item[this.valueFieldName] === selected;
  /**
   * Tableau d'objets qui doivent contenir chacun à minima 2 attributs :
   *  - un attribut correspondant à la valeur de l'input `valueFieldName` et
   * contenant l'identifiant de la zone géographique.
   *  - un attribut `area_name` contenant l'intitulé de la zone géographique
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
  areas_input$ = new Subject<string>();
  areas: Observable<any>;
  loading = false;
  // private defaultItems = [];

  constructor(private dataService: DataFormService) {
    super();
  }

  ngOnInit() {
    // Patch to force 'id_area' as default value for valueFieldName
    // when this attribute is defined in HTML but with an undefined value
    // TODO : try to resolve this problem in DynamicForm with conditional attribute maybe
    this.valueFieldName = this.valueFieldName === undefined ? 'id_area' : this.valueFieldName;

    this.updateParentFormControl();
    this.getAreas();
  }

  /**
   * Merge initial 100 areas + default values (for update)
   */
  initalAreas(): Observable<any> {
    return zip(
      this.dataService.getAreas(this.typeCodes).pipe(map((data) => this.formatAreas(data))), // Default items
      of(this.defaultItems) // Default items in update mode
    ).pipe(
      map((areasArrays) => {
        // Remove dubplicates items
        const items = areasArrays[0];
        const defaultItems = areasArrays[1];
        if (defaultItems && defaultItems.length > 0) {
          const filteredItems = items.filter((area) => {
            return !defaultItems.some(
              (defaultArea) => defaultArea[this.valueFieldName] === area[this.valueFieldName]
            );
          });
          return filteredItems.concat(defaultItems);
        } else {
          return items;
        }
      })
    );
  }

  private updateParentFormControl() {
    // Replace objects by valueFieldName values
    if (this.parentFormControl.value) {
      this.defaultItems = this.parentFormControl.value;
      this.parentFormControl.setValue(this.defaultItems.map(item => item[this.valueFieldName]));
    }
  }
  //TODO: check merge
  getAreas() {
    this.areas = concat(
      this.initalAreas(),
      this.areas_input$.pipe(
        debounceTime(200),
        distinctUntilChanged(),
        tap(() => (this.loading = true)),
        switchMap((term) => {
          return term && term.length >= 2
            ? this.dataService.getAreas(this.typeCodes, term).pipe(
                map((data) => this.formatAreas(data)),
                catchError(() => of([])), // Empty list on error
                tap(() => (this.loading = false))
              )
            : of([]);
        }),
        tap(() => (this.loading = false))
      )
    );
  }

  /**
   * Ajouter entre parenthèse le numéro du département si le premier objet
   * contient un champ `id_type` correspondant au type commune (=COM).
   * @param data Liste d'objets contenant des infos sur des zones géographiques.
   */
  private formatAreas(data: Partial<{ id_type: number; area_code: string }>[]) {
    if (data.length > 0 && data[0]['area_type']['type_code'] === 'COM') {
      return data.map((element) => {
        element['area_name'] = `${element['area_name']} (${element.area_code.substring(0, 2)}) `;
        return element;
      });
    }
    return data;
  }
}
