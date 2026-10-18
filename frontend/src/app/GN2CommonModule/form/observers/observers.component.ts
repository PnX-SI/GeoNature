import { DesignStyle } from '../items-select/items-select.component';
import { OnInit, Component, Input, ViewEncapsulation, SimpleChanges } from '@angular/core';
import { Observer } from '../../interfaces';
import { ObserversSource } from './observers.source';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';

/**
 * Ce composant permet d'afficher un input de type "autocomplete" sur un liste d'observateur définit dans le schéma ``utilisateur.t_menus`` et ``utilisateurs.cor_role_menu``.
 * Il permet de sélectionner plusieurs utilisateurs dans le même input.
 * Renvoie l'objet: ```{
    "nom_complet": "ADMINISTRATEUR test",
    "nom_role": "Administrateur",
    "id_role": 1,
    "prenom_role": "test",
    "id_menu": 9
  }
  ```
 */
@Component({
  selector: 'pnx-observers',
  templateUrl: './observers.component.html',
  styleUrls: ['./observers.component.scss'],
  encapsulation: ViewEncapsulation.None,
})
export class ObserversComponent extends GenericFormComponent implements OnInit {
  /**
   *  Id de la liste d'utilisateur (table ``utilisateur.t_menus``) (obligatoire)
   */
  @Input() idMenu: number;
  @Input() idList: number;
  @Input() codeList: string;
  @Input() bindAllItem = false;
  @Input() bindValue: string = null;
  @Input() compareWith = (c1, c2) => {
    return c1.id_role === c2.id_role;
  };
  @Input() observers: Observable<Array<Observer>>;
  @Input() placeHolder: string = null;
  /** Design of the select, see ``pnx-items-select`` */
  @Input() designStyle: DesignStyle = 'material';

  constructor(private _source: ObserversSource) {
    super();
  }

  ngOnInit() {
    super.ngOnInit();
    this.bindValue = this.bindAllItem ? null : this.bindValue;
    this.multiSelect = this.multiSelect ? true : this.multiSelect;
    this.placeHolder ??= this.label;

    // uniformise as IdList the id of list
    // retrocompat: keep idMenu
    if (this.idList) {
      this.idMenu = this.idList;
    }

    if (!this.observers) {
      this.observers = this._source.load({ idMenu: this.idMenu, codeList: this.codeList });
      if (!this.idMenu && this.codeList) {
        // the value of the control has to be set again once the list of the code is loaded
        this.observers = this.observers.pipe(
          map((data) => {
            if (this.parentFormControl.value) {
              this.parentFormControl.setValue(this.parentFormControl.value);
            }
            return data;
          })
        );
      }
    }
  }

  formatobs(obs: string): string {
    return obs.toLowerCase().replace(' ', '');
  }
}
