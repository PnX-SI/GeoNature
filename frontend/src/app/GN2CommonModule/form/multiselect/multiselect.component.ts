import { Component, OnInit, Input, EventEmitter, Output, OnChanges } from '@angular/core';
import { FormControl } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';

/**
 * Ce composant permet d'afficher un input de type multiselect à partir d'une liste de valeurs passé en Input
 *
 * @example
 * <pnx-multiselect
 * [values]="organisms"
 * [parentFormControl]="form.controls.organisms"
 * [keyLabel]="'nom_organisme'"
 * [keyValue]="'id_organisme"'
 * [label]="'Organisme'"
 * (onChange)="doWhatever($event)
 * (onDelete)="deleteCallback($event)"
 * (onSearch)="filterItems($event)">
 * </pnx-multiselect>
 */
@Component({
  selector: 'pnx-multiselect',
  templateUrl: './multiselect.component.html',
  styleUrls: ['./multiselect.component.scss']
})
export class MultiSelectComponent implements OnInit, OnChanges {
  public selectedItems = [];
  public searchControl = new FormControl();
  public formControlValue = [];
  public savedValues = [];

  @Input() parentFormControl: FormControl;
  //** Valeurs à afficher dans la liste déroulante. Doit être un tableau de dictionnaire */
  @Input() values: Array<any>;
  /**
   * Clé du dictionnaire de valeur que le composant doit prendre pour l'affichage de la liste déroulante
   */
  @Input() keyLabel: string;
  /** Clé du dictionnaire que le composant doit passer au formControl */
  @Input() keyValue: string;
  /**              Est-ce que le composant doit afficher l'item "tous" dans les options du select ?  */
  @Input() displayAll: boolean;
  // enable the search bar when dropdown
  @Input() searchBar: boolean;
  // disable the input
  @Input() disabled: boolean;
  // label displayed above the input
  @Input() label: any;
  /**
   * Booléan qui permet de passer tout l'objet au formControl, et pas seulement une propriété de l'objet renvoyé par l'API. Facultatif, par défaut à ``false``, c'est alors l'attribut passé en Input ``keyValue`` qui est renvoyé au formControl.
   * Lorsque l'on passe ``true`` à cet Input, l'Input ``keyValue`` devient inutile.
   */
  @Input() bindAllItem: false;
  // time before the output are triggered
  @Input() debounceTime: number;
  @Output() onSearch = new EventEmitter();
  @Output() onChange = new EventEmitter<any>();
  @Output() onDelete = new EventEmitter<any>();
  constructor(private _translate: TranslateService) {}

  // Component to generate a custom multiselect input with a search bar (which can be disabled)
  // you can pass whatever callback to the onSearch output, to trigger database research or simple search on an array

  ngOnInit() {
    this.debounceTime = this.debounceTime || 100;
    this.disabled = this.disabled || false;
    this.searchBar = this.searchBar || false;
    this.displayAll = this.displayAll || false;

    // set the value
    if (this.values && this.parentFormControl.value) {
      if (this.bindAllItem) {
        this.values.forEach(value => {
          if (this.parentFormControl.value.indexOf(value) !== -1) {
            this.selectedItems.push(value);
          }
        });
      } else {
        this.values.forEach(value => {
          if (this.parentFormControl.value.indexOf(value[this.keyValue]) !== -1) {
            this.selectedItems.push(value);
          }
        });
      }
    }

    // subscribe and output on the search bar
    this.searchControl.valueChanges
      .debounceTime(this.debounceTime)
      .distinctUntilChanged()
      .subscribe(value => {
        this.onSearch.emit(value);
      });

    this.parentFormControl.valueChanges.subscribe(value => {
      // filter the list of options to not display twice an item
      if (value === null) {
        this.selectedItems = [];
        this.formControlValue = [];
        this.values = this.savedValues;
      } else {
        if (this.selectedItems.length === 0) {
          value.forEach(item => {
            this.selectedItems.push(item);
            this.formControlValue.push(item);
          });
        }
      }
    });
  }

  addItem(item) {
    // remove element from the items list to avoid doublon
    this.values = this.values.filter(curItem => {
      return curItem[this.keyLabel] !== item[this.keyLabel];
    });
    if (item === 'all') {
      this.selectedItems = [];
      this._translate.get('AllItems', { value: 'AllItems' }).subscribe(value => {
        const objAll = {};
        objAll[this.keyLabel] = value;
        this.selectedItems.push(objAll);
      });
      this.formControlValue = [];
      this.parentFormControl.patchValue([]);
      return;
    }
    // set the item for the formControl
    let updateItem;
    if (this.bindAllItem) {
      updateItem = item;
    } else {
      updateItem = item[this.keyValue];
    }
    this.selectedItems.push(item);
    this.formControlValue.push(updateItem);
    // set the item for the formControl
    this.parentFormControl.patchValue(this.formControlValue);

    this.searchControl.reset();
    this.onChange.emit(item);
  }

  removeItem($event, item) {
    // remove element from the items list to avoid doublon
    this.values = this.values.filter(curItem => {
      return curItem[this.keyLabel] !== item[this.keyLabel];
    });
    // disable event propagation
    $event.stopPropagation();
    // push the element in the items list
    this.values.push(item);
    this.selectedItems = this.selectedItems.filter(curItem => {
      return curItem[this.keyLabel] !== item[this.keyLabel];
    });
    if (this.bindAllItem) {
      this.formControlValue = this.parentFormControl.value.filter(el => {
        return el !== item;
      });
    } else {
      this.formControlValue = this.parentFormControl.value.filter(el => {
        return el !== item[this.keyValue];
      });
    }
    this.parentFormControl.patchValue(this.formControlValue);

    this.onDelete.emit(item);
  }

  removeDoublon() {
    if (this.values && this.formControlValue) {
      this.values = this.values.filter(v => {
        let isInArray = false;

        this.formControlValue.forEach(element => {
          if (this.bindAllItem) {
            if (v[this.keyValue] === element[this.keyValue]) {
              isInArray = true;
            }
          } else {
            if (v[this.keyValue] === element) {
              isInArray = true;
            }
          }
        });
        return !isInArray;
      });
    }
  }

  ngOnChanges(changes) {
    if (changes.values && changes.values.currentValue) {
      this.savedValues = changes.values.currentValue;
      // remove doublon in the dropdown lists
      // @FIXME: timeout to wait for the formcontrol to be updated
      setTimeout(() => {
        this.removeDoublon();
      }, 2000);
    }
  }
}
