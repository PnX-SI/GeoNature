import { Component, OnInit, Input } from '@angular/core';
import { DataFormService } from '../data-form.service';
import { FormControl } from '@angular/forms';
import { CommonService } from '@geonature_common/service/common.service';

/**
 * Ce composant a le même comportement que pnx-areas.
 *
 * Il encapsule [le composant pnx-multiselect]{@link MultiSelectComponent}
 * et lui passe une liste de noms scientifiques supérieurs à un rang donné.
 *
 * La liste de noms scientifiques correspond aux caractères tapés dans la
 * zone de recherche.
 *
 * Au maximum 20 noms sont affichés.
 *
 * @example
 * <pnx-taxa
 *   label="Mon libellé de champ"
 *   rank="GN"
 *   [parentFormControl]="form.controls.taxa"
 *   [bindAllItem]="true"
 *   [debounceTime]="400"
 * >
 * </pnx-taxa>
 */
@Component({
  selector: 'pnx-taxa',
  templateUrl: 'taxa.component.html'
})
export class TaxaComponent implements OnInit {
  /** Contient un tableau d'objets. L'attribut "displayName" des objets
   * sert à l'affichage du nom.
   */
  public taxa: any;
  /** Rang minimum des noms recherchés.
   * Utiliser une valeur du champ "id_rang" de la table "bib_taxref_rangs".
   *
   * Par défaut, le rang défini correspond au Genre (=GN).
   */
  @Input() rank: string = 'GN';
  /** Intitulé du champ. */
  @Input() label: string;
  /** Passer une instance de FormControl afin de pouvoir valider le
   * formulaire et récupérer la valeur de ce champ.
   */
  @Input() parentFormControl: FormControl;
  /** Indique si tout l'objet correspondant à la sélection doit être
   * passé au formControl (=true) ou seulement la valeur de la propriété
   * "cd_nom" (=false).
   *
   * Par défaut, seul la valeur de "cd_nom" est transmise (=false).
   */
  @Input() bindAllItem: false;
  /** Temps en millisecondes avant lancement d'une recherche avec les
   * caractères saisis dans la zone de recherche.
   *
   * Voir le composant [pnx-multiselect]{@link MultiSelectComponent} pour
   * la valeur par défaut.
   */
  @Input() debounceTime: number;
  /** Désactive le composant. */
  @Input() disabled: boolean = false;

  /** @ignore */
  constructor(
    private dataService: DataFormService,
    private commonService: CommonService
  ) {}

  ngOnInit() {
    this.taxa = [];
  }

  /** Relance un appel à l'API fournissant les noms scientifiques si le
   * nombre de caractères saisies dans le zone de recherche est supérieur
   * ou égal à 2.
   *
   * La liste de noms est réinitialisée quand un nom est sélectionné ou
   * la zone de recherche vidée.
   *
   * @param taxon_name La chaine de caractère saisie dans la zone de
   * recherche.
  */
  refreshTaxaList(taxon_name) {
    if (taxon_name && taxon_name.length >= 2) {
      this.dataService.getHigherTaxa(this.rank, taxon_name).subscribe(
        data => {
          this.taxa = data;
        },
        err => {
          if (err.status === 404) {
            this.taxa = [{ displayName: 'No data to display' }];
          } else {
            this.taxa = [];
            this.commonService.translateToaster('error', 'ErrorMessage');
          }
        }
      );
    } else if (!taxon_name) {
      this.taxa = [];
    }
  }
}
