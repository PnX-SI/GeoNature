import { OnInit, Component, Input, ViewEncapsulation, SimpleChanges } from '@angular/core';
import { DataFormService } from '../data-form.service';
import { BehaviorSubject, Observable, combineLatest } from 'rxjs';
import { map, shareReplay } from 'rxjs/operators';
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
  @Input() observers: Observable<Array<any>>;
  @Input() placeHolder: string = null;
  @Input() designStyle: 'bootstrap' | 'material' = 'bootstrap';

  search = '';
  filteredObservers$: Observable<Array<any>> = new BehaviorSubject<Array<any>>([]);
  private searchTerm$ = new BehaviorSubject<string>('');

  constructor(private _dfService: DataFormService) {
    super();
  }

  ngOnInit() {
    super.ngOnInit();
    this.bindValue = this.bindAllItem ? null : this.bindValue;
    this.multiSelect = this.multiSelect ? true : this.multiSelect;
    this.placeHolder ??= this.label;
    this.designStyle = this.designStyle || 'bootstrap';

    // uniformise as IdList the id of list
    // retrocompat: keep idMenu
    if (this.idList) {
      this.idMenu = this.idList;
    }

    if (!this.observers) {
      // si idMenu
      if (this.idMenu) {
        this.observers = this._dfService.getObservers(this.idMenu);
      } else if (this.codeList) {
        this.observers = this._dfService.getObserversFromCode(this.codeList).pipe(
          map((data) => {
            if (this.parentFormControl.value) {
              this.parentFormControl.setValue(this.parentFormControl.value);
            }
            return data;
          })
        );
      } else {
        this.observers = this._dfService.getObservers();
      }
    }

    // share a single underlying request between the async pipe (options list)
    // and the search-filtered observable below
    this.observers = this.observers.pipe(shareReplay(1));

    this.filteredObservers$ = combineLatest([this.observers, this.searchTerm$]).pipe(
      map(([items, search]) =>
        (items || []).filter(
          (item) => !search || item.nom_complet?.toLowerCase().includes(search.toLowerCase())
        )
      )
    );
  }

  formatobs(obs: string): string {
    return obs.toLowerCase().replace(' ', '');
  }

  searchChanged(event: string) {
    this.search = event;
    this.searchTerm$.next(event);
  }

  valueOf(item: any) {
    return this.bindValue ? item[this.bindValue] : item;
  }

  compareObservers = (c1: any, c2: any): boolean => {
    return this.bindValue ? c1 === c2 : this.compareWith(c1, c2);
  };
}
