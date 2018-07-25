import {
  Component,
  OnInit,
  Input,
  EventEmitter,
  Output,
  OnChanges,
  AfterViewInit
} from '@angular/core';
import { FormControl } from '@angular/forms';
import { Subscription } from 'rxjs/Subscription';

@Component({
  selector: 'pnx-select-search',
  templateUrl: './select-search.component.html',
  styleUrls: ['./select-search.component.scss']
})
export class SelectSearchComponent implements OnInit, OnChanges {
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
  // enabled multiselect
  @Input() multiselect: boolean;
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
  public subscription: Subscription;
  constructor() {}

  // Component to generate a custom select input with a search bar (which can be disabled)
  // you can pass whatever callback to the onSearch output, to trigger database research or simple search on an array
  // With the multiselect Input you can control if multiple items can be selected

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
        console.log('EMIT');
        console.log(value);
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
      this.parentFormControl.patchValue(null);
      return;
    }
    // set the item for the formControl
    let updateItem;
    if (this.keyValue) {
      updateItem = item[this.keyValue];
    } else {
      updateItem = item;
    }
    console.log(this.keyValue);
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

    console.log(item);
    if (this.keyValue) {
      this.formControlValue = this.formControlValue.filter(el => {
        return el !== item[this.keyValue];
      });
    } else {
      this.formControlValue = this.formControlValue.filter(el => {
        return el !== item;
      });
    }
    console.log(this.formControlValue);
    this.parentFormControl.patchValue(this.formControlValue);

    this.onDelete.emit(item);
  }

  ngOnChanges(changes) {
    // if (changes.values && changes.values.currentValue) {
    //   this.itemsLoaded.next(changes.values.currentValue);
    // }
  }
}
