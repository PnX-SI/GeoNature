import { Component, Input } from '@angular/core';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';

@Component({
  selector: 'pnx-dumb-select',
  templateUrl: 'dumb-select.component.html'
})

/**
 * Ce composant permet de créer un "input" de type "select" à partir d'une liste d'items
 * fournie par le composant de rang superieur.
 * A la difference du component ``pnx-nomenclature`` celui-ci ne charge pas ses données
 * il ne renvoie également l'ensemble de l'objet "nomenclature" au formulaire auquel il est rattaché
 *
 * NB: La table ``ref_nomenclatures.cor_taxref_nomenclature`` permet de faire corespondre des items de nomenclature à des groupe INPN et des règne. A chaque fois que ces deux derniers input sont modifiés, la liste des items est rechargée.
 * Ce composant peut ainsi être couplé au composant taxonomy qui renvoie le regne et le groupe INPN de l'espèce saisie.
 *
 * @example
 * <pnx-dumb-select
 * [parentFormControl]="occtaxForm.controls.id_nomenclature_etat_bio"
 * [items]="items"
 * [comparedKey]="comparedKey"
 * [titleKey]="titleKey"
 * [displayedKey]="displayedKey">
 * </pnx-nomenclature>
 */
export class DumbSelectComponent extends GenericFormComponent {
  constructor() {
    super();
  }

  /**
   * Mnémonique du type de nomenclature qui doit être affiché dans la liste déroulante.
   *  Table``ref_nomenclatures.bib_nomenclatures_types`` (obligatoire)
   */
  @Input() items: string;
  /**
   * Clé de l'item utilisé pour comparer les items et afficher la valeur courante
   * Obligatoire
   */
  @Input() comparedKey: string;
  /**
   * Clé de l'item utilisé pour l'attribut 'title' de la balise select
   * Obligatoire
   */
  @Input() titleKey: string;
  /**
   * Clé de l'item utilsé pour afficher dans le select
   * Obligatoire
   */
  @Input() displayedKey: string;

  /** Affiche un item avec pour valeur null */
  @Input() displayNullValue = false;

  /** Label de la valeure Null */
  @Input() nullValueLabel: string;

  compareFn(c1: any, c2: any): boolean {
    return c1 && c2 ? c1[this.comparedKey] === c2[this.comparedKey] : c1 === c2;
  }
}
