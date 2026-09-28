import { OnInit, OnDestroy, Component, Input, ViewEncapsulation } from '@angular/core';
import { DataFormService } from '../data-form.service';
import { BehaviorSubject, Observable, Subject, Subscription, forkJoin, of } from 'rxjs';
import {
  catchError,
  debounceTime,
  distinctUntilChanged,
  map,
  switchMap,
  tap,
} from 'rxjs/operators';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';

/**
 * Ce composant permet d'afficher un input de type "autocomplete" sur un liste d'observateur définit dans le schéma ``utilisateur.t_menus`` et ``utilisateurs.cor_role_menu``.
 * Il permet de sélectionner plusieurs utilisateurs dans le même input.
 *
 * La recherche est effectuée côté serveur (paramètre ``nom_complet`` des routes ``/users/menu*``)
 * dès que l'utilisateur a saisi au moins ``charNumber`` caractères (hors espaces).
 * Les valeurs déjà présentes dans le contrôle (mode édition) sont résolues via le paramètre
 * ``id_role`` afin d'afficher leur libellé.
 *
 * Si l'input ``observers`` est fourni, la liste est entièrement chargée côté client
 * et filtrée localement (pas de requête de recherche).
 *
 * Renvoie l'objet: ```{
    "nom_complet": "ADMINISTRATEUR test",
    "nom_role": "Administrateur",
    "id_role": 1,
    "prenom_role": "test",
    "id_menu": 9
  }
  ```
  ou uniquement l'``id_role`` si ``bindValue="id_role"``.
 */
@Component({
  selector: 'pnx-observers',
  templateUrl: './observers.component.html',
  styleUrls: ['./observers.component.scss'],
  encapsulation: ViewEncapsulation.None,
})
export class ObserversComponent extends GenericFormComponent implements OnInit, OnDestroy {
  /**
   *  Id de la liste d'utilisateur (table ``utilisateur.t_menus``)
   */
  @Input() idMenu: number;
  @Input() idList: number;
  @Input() codeList: string;
  @Input() bindAllItem = false;
  @Input() bindValue: string = null;
  @Input() compareWith = (c1, c2) => {
    const id1 = ObserversComponent.idOf(c1);
    const id2 = ObserversComponent.idOf(c2);
    return id1 !== null && id2 !== null && String(id1) === String(id2);
  };
  /**
   * Liste d'observateurs pré-chargée : si fournie, pas de recherche côté serveur,
   * le filtrage est réalisé localement.
   */
  @Input() observers: Observable<Array<any>>;
  @Input() placeHolder: string = null;
  /** Nombre minimum de caractères (hors espaces) avant de lancer une recherche */
  @Input() charNumber: number = 2;
  /** Nombre maximum de résultats renvoyés par la recherche */
  @Input() limit: number = 50;

  /** true : recherche côté serveur (typeahead) ; false : liste `observers` fournie en entrée */
  serverSide = false;
  /** Items affichés par le ng-select */
  items$: Observable<Array<any>>;
  observersInput$ = new Subject<string>();
  loading = false;

  private _items$ = new BehaviorSubject<Array<any>>([]);
  /** Cache des observateurs connus (résultats de recherche et valeurs résolues), indexé par id_role */
  private _knownObservers = new Map<string, any>();
  private _subscriptions: Subscription[] = [];

  constructor(private _dfService: DataFormService) {
    super();
  }

  static idOf(value: any): any {
    if (value === null || value === undefined) {
      return null;
    }
    return typeof value === 'object' ? (value.id_role ?? null) : value;
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

    if (this.observers) {
      // Pre-loaded list: client-side filtering
      this.serverSide = false;
      this.items$ = this.observers;
      return;
    }

    this.serverSide = true;
    this.items$ = this._items$.asObservable();

    this._subscriptions.push(
      this.observersInput$
        .pipe(
          map((term) => (term ?? '').toString().trim()),
          debounceTime(300),
          distinctUntilChanged(),
          switchMap((term) => {
            if (term.length < this.charNumber) {
              this.loading = false;
              return of(null);
            }
            this.loading = true;
            return this._fetchObservers({ nom_complet: term, limit: this.limit }).pipe(
              catchError(() => of([])) // Empty list on error
            );
          })
        )
        .subscribe((results) => {
          this.loading = false;
          if (results === null) {
            // Search term too short: only display the current selection
            this._items$.next(this._selectedKnownObservers());
          } else {
            this._cacheObservers(results);
            this._items$.next(results);
          }
        })
    );

    // Resolve the initial value, then any value set programmatically (edit mode, patchValue...)
    this._resolveValue(this.parentFormControl?.value);
    if (this.parentFormControl) {
      this._subscriptions.push(
        this.parentFormControl.valueChanges.subscribe((value) => this._resolveValue(value))
      );
    }
  }

  ngOnDestroy() {
    this._subscriptions.forEach((sub) => sub.unsubscribe());
    super.ngOnDestroy();
  }

  formatobs(obs: string): string {
    return obs.toLowerCase().replace(' ', '');
  }

  isTermTooShort(term: string): boolean {
    return (term ?? '').trim().length < this.charNumber;
  }

  /**
   * Call the right `/users/menu*` route depending on idMenu / codeList.
   */
  private _fetchObservers(params: { [key: string]: any }): Observable<Array<any>> {
    if (this.idMenu) {
      return this._dfService.getObservers(this.idMenu, params);
    } else if (this.codeList) {
      return this._dfService.getObserversFromCode(this.codeList, params);
    }
    return this._dfService.getObservers(null, params);
  }

  private _cacheObservers(observers: Array<any>) {
    for (const obs of observers ?? []) {
      const id = ObserversComponent.idOf(obs);
      if (id !== null) {
        this._knownObservers.set(String(id), obs);
      }
    }
  }

  private _valueAsArray(value: any): Array<any> {
    if (value === null || value === undefined || value === '') {
      return [];
    }
    return Array.isArray(value) ? value : [value];
  }

  private _selectedKnownObservers(): Array<any> {
    return this._valueAsArray(this.parentFormControl?.value)
      .map((v) => this._knownObservers.get(String(ObserversComponent.idOf(v))))
      .filter((obs) => obs !== undefined);
  }

  /**
   * Make sure every selected value is present in the ng-select items so its label is displayed.
   * Unknown ids are fetched once with the `id_role` parameter.
   */
  private _resolveValue(value: any) {
    const values = this._valueAsArray(value);
    if (values.length === 0) {
      return;
    }

    // Objects already carrying a label are used as is
    this._cacheObservers(
      values.filter((v) => v !== null && typeof v === 'object' && v.nom_complet)
    );

    const ids = values.map((v) => ObserversComponent.idOf(v)).filter((id) => id !== null);
    const currentItems = this._items$.getValue();
    const isDisplayed = (id: any) =>
      currentItems.some((item) => String(ObserversComponent.idOf(item)) === String(id));
    if (ids.every(isDisplayed)) {
      return;
    }

    const unknownIds = ids.filter((id) => !this._knownObservers.has(String(id)));
    const resolve$: Observable<any> = unknownIds.length
      ? this._fetchObservers({ id_role: unknownIds }).pipe(
          catchError(() => of([])),
          tap((observers) => this._cacheObservers(observers)),
          // Roles which are not part of the list (e.g. removed from it since) : fallback on /users/role
          switchMap(() => {
            const stillUnknown = unknownIds.filter((id) => !this._knownObservers.has(String(id)));
            if (!stillUnknown.length) {
              return of([]);
            }
            return forkJoin(
              stillUnknown.map((id) => this._dfService.getRole(id).pipe(catchError(() => of(null))))
            ).pipe(tap((roles) => this._cacheObservers(roles.filter((role) => role !== null))));
          })
        )
      : of([]);

    resolve$.subscribe(() => {
      const items = this._items$.getValue();
      const missing = this._selectedKnownObservers().filter(
        (obs) =>
          !items.some(
            (item) => String(ObserversComponent.idOf(item)) === String(ObserversComponent.idOf(obs))
          )
      );
      if (missing.length) {
        this._items$.next(items.concat(missing));
      }
    });
  }
}
