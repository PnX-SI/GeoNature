import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';

import { Subject, Observable, of, concat, zip } from 'rxjs';
import {
  distinctUntilChanged,
  debounceTime,
  switchMap,
  tap,
  catchError,
  map,
} from 'rxjs/operators';

import { Area } from '../../interfaces';
import { AreasSource } from './areas.source';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { mergeDefaultItems } from './areas.utils';
import { DesignStyle } from '../items-select/items-select.component';

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
 * d'id de zones géo. Ces id seront comparés à l'aide de la fonction de l'input
 * `compareWith` aux objets passés dans l'input `defaultItems`.
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
  /** Design of the select, see ``pnx-items-select`` */
  @Input() designStyle: DesignStyle = 'material';
  /**
   * Do not get the geom from the getArea call, for performances
   */
  @Input() withoutGeom: Boolean = false;
  /**
   * Nom du champ à utiliser pour déterminer la valeur à utiliser pour le
   * contenu du `FormControl`.
   * Si vous souhaitez forcer le maintient dans `parentFormControl` d'un
   * tableau d'objets comprenant le champ identifiant et le champ pour
   * l'affichage (`area_name`), vous pouvez l'indiquer en passant une
   * valeur `null` à cet attribut.
   * Exemple :
   * [valueFieldName]="'id_type'"
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
  @Input() defaultItems: Array<Area> = [];
  /**
   * Permet découter les changements sur la sélection de ng-select.
   * Retourne un tableau d'objets. Les objets correspondent aux items
   * sélectionnés. Chaque objet contient à minima 2 attributs : un
   * correspondant à l'input `valueFieldName`, l'autre est `displayName`.
   */
  @Output() onSelectionChange = new EventEmitter<any>();
  areas_input$ = new Subject<string>();
  areas: Observable<Array<Area>>;
  loading = false;
  params = {};

  constructor(private _source: AreasSource) {
    super();
  }

  ngOnInit() {
    super.ngOnInit();
    this.params['type_code'] = this.typeCodes;
    this.params['without_geom'] = this.withoutGeom;
    this.valueFieldName = this.valueFieldName === undefined ? 'id_area' : this.valueFieldName;

    this.getAreas();
  }

  /**
   * Merge initial 100 areas + default values (for update)
   */
  initialAreas(): Observable<Array<Area>> {
    return zip(
      this._source.load(this.params), // Default items
      of(this.defaultItems) // Default items in update mode
    ).pipe(
      map(([items, defaultItems]) => mergeDefaultItems(items, defaultItems, this.valueFieldName))
    );
  }

  getAreas() {
    this.areas = concat(
      this.initialAreas(),
      this.areas_input$.pipe(
        debounceTime(200),
        distinctUntilChanged(),
        tap(() => (this.loading = true)),
        switchMap((term) => {
          this.params['area_name'] = term;
          return term && term.length >= 2
            ? this._source.load(this.params).pipe(
                catchError(() => of([])), // Empty list on error
                tap(() => (this.loading = false))
              )
            : of([]);
        }),
        tap(() => (this.loading = false))
      )
    );
  }
}
