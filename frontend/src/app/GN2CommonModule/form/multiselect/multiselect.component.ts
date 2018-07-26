import { Component, OnInit, Input, EventEmitter, Output, AfterViewInit } from '@angular/core';
import { FormControl } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';

@Component({
  selector: 'pnx-multiselect',
  templateUrl: './multiselect.component.html',
  styleUrls: ['./multiselect.component.scss']
})
export class MultiSelectComponent implements OnInit {
  public selectedItems = [];
  public searchControl = new FormControl();
  public formControlValue = [];

  @Input() parentFormControl: FormControl;
  // value of the dropddown
  @Input() values: Array<any>;
  // key of the array of options for the input displaying
  @Input() keyLabel: string;
  // key of the array of options for the formControl value
  @Input() keyValue: string;
  // Display all in the select list (set the control to null)
  @Input() displayAll: boolean;
  // enable the search bar when dropdown
  @Input() searchBar: boolean;
  // disable the input
  @Input() disabled: boolean;
  // label displayed above the input
  @Input() label: any;
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

    // subscribe and output on the search bar
    this.searchControl.valueChanges
      .filter(value => value !== null)
      .debounceTime(this.debounceTime)
      .distinctUntilChanged()
      .subscribe(value => {
        this.onSearch.emit(value);
      });

    this.parentFormControl.valueChanges.subscribe(value => {
      if (value === null) {
        this.selectedItems = [];
        this.formControlValue = value;
      } else {
        if (this.selectedItems.length === 0) {
          value.forEach(item => {
            this.selectedItems.push(item);
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
    if (this.keyValue) {
      updateItem = item[this.keyValue];
    } else {
      updateItem = item;
    }
    this.selectedItems.push(item);
    this.formControlValue.push(updateItem);
    // set the item for the formControl
    this.parentFormControl.patchValue(this.formControlValue);

    this.searchControl.reset();
    this.onChange.emit(item);
  }

  removeItem(item) {
    // push the element in the items list
    this.values.push(item);
    this.selectedItems = this.selectedItems.filter(curItem => {
      return curItem[this.keyLabel] !== item[this.keyLabel];
    });
    if (this.keyValue) {
      this.formControlValue = this.parentFormControl.value.filter(el => {
        return el !== item[this.keyValue];
      });
    } else {
      this.formControlValue = this.parentFormControl.value.filter(el => {
        return el !== item;
      });
    }
    this.parentFormControl.patchValue(this.formControlValue);

    this.onDelete.emit(item);
  }
}
