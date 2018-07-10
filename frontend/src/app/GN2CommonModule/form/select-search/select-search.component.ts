import { Component, OnInit, Input, EventEmitter, Output } from '@angular/core';
import { FormControl } from '@angular/forms';

@Component({
  selector: 'pnx-select-search',
  templateUrl: './select-search.component.html',
  styleUrls: ['./select-search.component.scss']
})
export class SelectSearchComponent implements OnInit {
  public currentValue = null;
  public selectedItems = [];
  public searchControl = new FormControl();
  @Input() parentFormControl: FormControl;
  // value of the options
  @Input() values: Array<any>;
  // key of the array of options
  @Input() key: string;
  @Input() multiselect: boolean;
  @Input() disabled: boolean;
  @Input() label: any;
  @Input() debounceTime: number;
  @Output() onSearch = new EventEmitter();
  @Output() onChange = new EventEmitter<any>();
  @Output() onDelete = new EventEmitter<any>();
  constructor() {}

  // Component to generate a custom select input with a search bar
  // you can pass whatever callback to the onSearch output, to trigger database research or simple search on an array
  // With the multiselect Input you can control if multiple items can be selected

  ngOnInit() {
    this.debounceTime = this.debounceTime || 100;
    this.disabled = this.disabled || false;
    this.searchControl.valueChanges
      .debounceTime(this.debounceTime)
      .distinctUntilChanged()
      .subscribe(value => {
        this.onSearch.emit(value);
      });

    this.parentFormControl.valueChanges.subscribe(value => {
      if (value === null) {
        if (this.multiselect) {
          this.selectedItems = [];
        } else {
          this.currentValue = null;
        }
      } else {
        if (this.multiselect && this.selectedItems.length === 0) {
          value.forEach(item => {
            this.selectedItems.push(item);
          });
        }
        if (!this.multiselect) {
          this.currentValue = value[this.key];
        }
      }
    });
  }

  addItem(item) {
    // remove element from the items list to avoid doublon
    this.values = this.values.filter(curItem => {
      return curItem[this.key] !== item[this.key];
    });
    if (this.multiselect) {
      this.selectedItems.push(item);
      this.parentFormControl.patchValue(this.selectedItems);
    } else {
      this.parentFormControl.patchValue(item);
    }
    this.searchControl.reset();
    this.onChange.emit(item);
  }

  removeItem(item) {
    // push the element in the items list
    if (this.multiselect) {
      this.values.push(item);
      this.selectedItems = this.selectedItems.filter(curItem => {
        return curItem[this.key] !== item[this.key];
      });
      this.parentFormControl.patchValue(this.selectedItems);
    } else {
      this.parentFormControl.patchValue(item);
    }
    this.onDelete.emit(item);
  }
}
