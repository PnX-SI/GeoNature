import { Component, OnInit, Input } from '@angular/core';

import { Subject, Observable, of, concat } from 'rxjs';
import { distinctUntilChanged, debounceTime, switchMap, tap, catchError, map, distinct } from 'rxjs/operators'

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
  templateUrl: 'areas.component.html'
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
   * Fonction de comparaison entre les élements sélectionnés et les éléments
   * affichés dans la liste des options.
   * @param item
   * @param selected
   * @returns
   */
  @Input() compareWith = (item, selected) => item[this.valueFieldName] === selected;
  areas_input$ = new Subject<string>();
  areas: Observable<any>;
  loading = false;
  private defaultItems = [];

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

  private updateParentFormControl() {
    // Replace objects by valueFieldName values
    if (this.parentFormControl.value) {
      this.defaultItems = this.parentFormControl.value;
      this.parentFormControl.setValue(this.defaultItems.map(item => item[this.valueFieldName]));
    }
  }

  getAreas() {
    this.areas = concat(
      concat(
        of(this.defaultItems), // Load items for update mode
        this.dataService.getAreas(this.typeCodes).pipe(map(data => this.formatAreas(data))) // Default items
      ).pipe(
        distinct(item => item[this.valueFieldName]) // Remove duplicates
      ),
      this.areas_input$.pipe(
        debounceTime(200),
        distinctUntilChanged(),
        tap(() => (this.loading = true)),
        switchMap(term => {
          return term && term.length >= 2
            ? this.dataService.getAreas(this.typeCodes, term).pipe(
                map(data => this.formatAreas(data)),
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
    if (data.length > 0 && data[0]['id_type'] === AppConfig.BDD.id_area_type_municipality) {
      return data.map(element => {
        element['area_name'] = `${element['area_name']} (${element.area_code.substring(0, 2)}) `;
        return element;
      });
    }
    return data;
  }
}
