import { OnInit, Component, Input, ViewEncapsulation } from '@angular/core';
import { DataFormService } from '../data-form.service';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { SelectFormComponent } from '../select-form.component';

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
 *
 * Deux rendus sont disponibles avec ``appearance`` : ``ng-select`` (défaut) ou ``material``.
 * Avec ``[autocomplete]="true"``, les utilisateurs ne sont
 * pas tous chargés : ils sont demandés à l'API au fur et à mesure de la saisie.
 */
@Component({
  selector: 'pnx-observers',
  templateUrl: './observers.component.html',
  styleUrls: ['./observers.component.scss', '../select-form.component.scss'],
  encapsulation: ViewEncapsulation.None,
})
export class ObserversComponent extends SelectFormComponent implements OnInit {
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
  @Input() observers: Observable<Array<any>>;

  constructor(private _dfService: DataFormService) {
    super();
  }

  ngOnInit() {
    this.bindValue = this.bindAllItem ? null : this.bindValue;
    this.multiSelect = this.multiSelect ? true : this.multiSelect;
    this.placeHolder ??= this.label;
    this.minSearchLength = 1;

    // uniformise as IdList the id of list
    // retrocompat: keep idMenu
    if (this.idList) {
      this.idMenu = this.idList;
    }

    if (!this.observers && !this.isRemote) {
      this.observers = this.fetchObservers();
      if (this.codeList) {
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
    super.ngOnInit();
  }

  private fetchObservers(params = {}): Observable<any[]> {
    if (this.idMenu) {
      return this._dfService.getObservers(this.idMenu, params);
    }
    if (this.codeList) {
      return this._dfService.getObserversFromCode(this.codeList, params);
    }
    return this._dfService.getObservers(null, params);
  }

  protected allItems(): Observable<any[]> {
    return this.observers;
  }

  protected fetch(term: string): Observable<any[]> {
    return this.fetchObservers({ nom_complet: term, limit: this.searchLimit });
  }

  protected itemId(item: any) {
    return item.id_role;
  }

  itemLabel(item: any): string {
    return item?.nom_complet ?? '';
  }

  formatobs(obs: string): string {
    return obs.toLowerCase().replace(' ', '');
  }
}
