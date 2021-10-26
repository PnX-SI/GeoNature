import {
  Component,
  OnInit,
  Input,
  EventEmitter,
  Output,
  OnChanges,
  ElementRef,
  ViewChild,
  HostListener,
  ViewChildren,
  QueryList,
} from '@angular/core';
import { FormControl } from '@angular/forms';
import { BehaviorSubject, combineLatest } from 'rxjs';
import { tap, distinctUntilChanged, filter, map, startWith, pairwise } from 'rxjs/operators';
import { TranslateService } from '@ngx-translate/core';

export enum KEY_CODE {
  ENTER = 'Enter',
  ARROW_DOWN = 'ArrowDown',
  ARROW_UP = 'ArrowUp',
}

/**
 * Ce composant permet d'afficher un input de type multiselect à partir
 * d'une liste de valeurs passé en Input.
 *
 * @example
 * <pnx-multiselect
 *   label="Organisme"
 *   [values]="organisms"
 *   [parentFormControl]="form.controls.organisms"
 *   keyLabel="nom_organisme"
 *   keyValue="id_organisme"
 *   (onChange)="doWhatever($event)"
 *   (onDelete)="deleteCallback($event)"
 *   (onSearch)="filterItems($event)"
 * >
 * </pnx-multiselect>
 */
@Component({
  selector: 'pnx-multiselect',
  templateUrl: './multiselect.component.html',
  styleUrls: ['./multiselect.component.scss']
})
export class MultiSelectComponent implements OnInit, OnChanges {
  public searchControl = new FormControl();
  public formControlValue = [];
  public savedValues = [];

  @Input() parentFormControl: FormControl;
  /** Valeurs brute transmise au component */
  private _values: BehaviorSubject<any[]> = new BehaviorSubject([]);
  @Input() 
  set values(val) { this._values.next(val); };
  get values(): any[] { return this._values.getValue(); };

  /** 
   * Valeurs affichées dans la liste déroulante. 
   * Correspond au contenu de this.value moins les valeurs filtrées par this.searchControl moins les valeurs déjà selectionnées présente dans this.selectedItems
   */
  public displayListValues: any[] = [];
  /** 
   * Filtre this.values selon le contenu de this.parentFormControl
   */
  public get selectedItems(): any[] { 
    if (this.parentFormControl.value === null) {
      return [];
    }

    return this.values.filter(elem => {
      return (this.bindAllItem ? this.parentFormControl.value.map(e => e[this.keyValue]) : this.parentFormControl.value)
                .includes(elem[this.keyValue]);
    });
  };

  /** Clé du dictionnaire de valeur que le composant doit prendre pour
   * l'affichage de la liste déroulante.
   */
  @Input() keyLabel: string;
  /** Clé du dictionnaire que le composant doit passer au formControl */
  @Input() keyValue: string;
  /** Est-ce que le composant doit afficher l'item "tous" dans les
   * options du select ?
   */
  @Input() displayAll: boolean = false;
  /** Affiche la barre de recherche (=true). */
  @Input() searchBar: boolean = false;
 /** Désactive le contrôle de formulaire. */
  @Input() disabled: boolean = false;
  /** Initutlé du contrôle de formulaire. */
  @Input() label: any;
  /**
   * Booléan qui permet de passer tout l'objet au formControl, et pas
   * seulement une propriété de l'objet renvoyé par l'API.
   *
   * Facultatif, par défaut à ``false``, c'est alors l'attribut passé en
   * Input ``keyValue`` qui est renvoyé au formControl.
   * Lorsque l'on passe ``true`` à cet Input, l'Input ``keyValue``
   * devient inutile.
   * L'API qui renvoit séléctionnées au formulaire doit être un tableau
   * d'entier et non un tableau d'items
   */
  @Input() bindAllItem: boolean = false;
  /** Temps en millisecondes avant lancement d'une recherche avec les
   * caractères saisis dans la zone de recherche.
   *
   * Par défaut, 100 millisecondes.
   */
  @Input() debounceTime: number = 100;
  /** Indique (=true) que le contenu de la liste doit être conscidéré
   * comme du HTML sûr.
   */
  @Input() isHtml: boolean = false;
  /** Action à exécuter lors d'une recherche. */
  @Output() onSearch = new EventEmitter();
  /** Action à exécuter lors du changement du contenu. */
  @Output() onChange = new EventEmitter<any>();
  /** Action à exécuter lors de la suppression du contenu. */
  @Output() onDelete = new EventEmitter<any>();

  private searchInputFocused: boolean = false;

  @ViewChild('buttonInput') buttonInput: ElementRef;
  @ViewChild('searchInput') searchInput: ElementRef;
  @ViewChildren('dropdownItem') dropdownList: QueryList<ElementRef>;

  /** Pour la selection au clavier. */
  public valSave;

  /** @ignore */
  constructor(private _translate: TranslateService) {}

  // you can pass whatever callback to the onSearch output, to trigger
  // database research or simple search on an array
  ngOnInit() {
    this.setObservables();

    // // Initialize attributes when "values" not change after ngOnInit...
    // if (this.values && this.parentFormControl.value) {
    //   this.values.forEach(item => {
    //     if (this.isInParentFormControl(item)) {
    //       this.selectedItems.push(item);
    //       // Component Taxa add data here with ngOnInit() when component Areas add with ngOnChange()
    //       let value = this.getValueFromItem(item);
    //       this.formControlValue.push(value);
    //     }
    //   });
    // }

    // Subscribe and output on the search bar
    this.searchControl.valueChanges
      .debounceTime(this.debounceTime)
      .distinctUntilChanged()
      .subscribe(value => {
        this.onSearch.emit(value);
      });
  }

  private setObservables() {

    combineLatest(
      this.parentFormControl.valueChanges
        .pipe(
          startWith([]),
          distinctUntilChanged((a, b) => JSON.stringify(a) === JSON.stringify(b)),
          filter((formValue: any[]|number[]) => formValue !== null),
          //return transform formValue to id key array
          map((formValue:any[]|number[]): number[] => this.bindAllItem ? formValue.map(e => e[this.keyValue]) : formValue)
        ),
      this._values.asObservable()
        .pipe(
          distinctUntilChanged((a, b) => JSON.stringify(a) === JSON.stringify(b)),
          filter((val: any[]) => val !== undefined && val.length),
          // pairwise(),
        )
    )
      .pipe(
        // //La manière de fonctionnement du searchInput (qui filtre en dehor du component) oblige à gérer le maintient des valeur du form dans la liste des valeurs.
        // map(([formValue, [_prev, _new]]: [number[], any[]]) => {
        //   console.log(formValue, _prev, _new);
        //   //item from _previous list
        //   const formItems = _prev.filter(elem => formValue.includes(elem[this.keyValue]))
        //                       //diff with new list to keep missing values
        //                      .filter(elem => !_new.includes(elem));
        //     console.log(formItems);
        //   return [formValue, _new.concat(formItems)];
        // }),
        //suppression des valeur selectionnées de la liste
        map(([formValue, values]: [number[], any[]]) => {
          return values.filter(elem => !(formValue.includes(elem[this.keyValue])));
        })
      )
      .subscribe((values) => this.displayListValues = values);

  }

  // private isInParentFormControl(value) {
  //   if (this.bindAllItem) {
  //     return (
  //       this.parentFormControl.value
  //         .map(item => item[this.keyValue])
  //         .indexOf(value[this.keyValue])
  //       !== -1
  //     );
  //   } else {
  //     return (this.parentFormControl.value.indexOf(value[this.keyValue]) !== -1)
  //   }
  // }

  /**
   * Ajoute tous les éléments courant au formControl (l'oject complet si
   * bindAllItems=True, sinon seulement l'id (keyValue)).
   */
  onSelectAll(): void {
    this.displayListValues.forEach(elem => this.addItem(elem));
  }

  /**
   * Ajoute l'élément courant au formControl (l'oject complet si
   * bindAllItems=True, sinon seulement l'id (keyValue)).
   * Filtre la liste pour ne pas afficher de doublon.
   * @param item : l'objet complet (pas l'id).
   */
  onSelectItem(item) {
    this.addItem(item);
    this.searchControl.reset();
    this.onChange.emit(this.getValueFromItem(item));
  }

  /**
   * Ajoute l'élément courant au formControl (l'oject complet si
   * bindAllItems=True, sinon seulement l'id (keyValue)).
   * Filtre la liste pour ne pas afficher de doublon.
   * @param item : l'objet complet (pas l'id).
   */
  private addItem(item, markDirty = true): void {
    if ( this.parentFormControl.value === null ) {
      this.parentFormControl.setValue([]);
    }
    const formValue = [...this.parentFormControl.value];
    formValue.push(this.getValueFromItem(item));
    this.parentFormControl.setValue(formValue);
  }

  onRemoveItem(item): void {
    const idx = (this.bindAllItem ? this.parentFormControl.value.map(e => e[this.keyValue]) : this.parentFormControl.value)
                .findIndex(elem => elem === item[this.keyValue]);

    if (idx !== -1) {
      //copy is necessary for set new distinct value to formControl
      const formValue = [...this.parentFormControl.value];
      formValue.splice(idx, 1);
      this.parentFormControl.setValue(formValue);
      this.onDelete.emit(item);
    }
  }

  private getValueFromItem(item) {
    // if bindAllItem -> push the whole object
    // else push only the key of the object( @Input keyValue)
    return (this.bindAllItem) ? item : item[this.keyValue];
  }

  onButtonInputClick() {
    if (this.searchBar) {
      // TODO: use ngx-bootstrap o ng-bootstrap for dropdown to use event dropdown shown !
      // TODO: use the event after show dropdown to avoid use of setTimeout() !
      setTimeout(() => {
        this.searchInput.nativeElement.focus();
      }, 0);
    }
  }

  onSearchInputFocus() {
    this.searchInputFocused = true;
  }

  onSearchInputBlur() {
    this.searchInputFocused = false;
  }

  onFocus(event) {
    this.valSave = ' ';
  }

  onBlur(event) {
    this.valSave = null;
  }

  setValSave(val = null) {
    this.valSave = val;
  }

  /** Gestion des touches pour la selection au clavier.
   *
   *  Les touche bas et haut pour permettre de se déplacer dans la liste.
   */
  @HostListener('window:keyup', ['$event'])
  keyEvent(event: KeyboardEvent) {
    // Enter (permet d'ouvrir le composant pour choisir un item)
    if (event.key === KEY_CODE.ENTER) {
      if (this.valSave) {
        const valSave = JSON.parse(JSON.stringify(this.valSave));
        this.buttonInput.nativeElement.click();
        this.buttonInput.nativeElement.focus();
        if (valSave !== ' ') {
          this.addItem(valSave);
          this.valSave = ' ';
        }
      }
    }
    // Down
    if (event.key === KEY_CODE.ARROW_DOWN) {
      // Select first dropdown entry if focus is in search input
      if (this.searchInputFocused && this.dropdownList.toArray().length > 0) {
        this.dropdownList.first.nativeElement.focus();
      } else if (this.valSave) {
        const element = (event.srcElement as HTMLTextAreaElement).nextElementSibling;
        if (element) {
          (element as HTMLElement).focus();
        }
      }
    }
    // Up
    if (event.key === KEY_CODE.ARROW_UP) {
      if (this.valSave) {
        const element = (event.srcElement as HTMLTextAreaElement).previousElementSibling;
        if (element) {
          (element as HTMLElement).focus();
        }
      }
    }
  }
}
