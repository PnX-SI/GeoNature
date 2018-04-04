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

  ngOnInit() {
    this.debounceTime = this.debounceTime || 100;
    this.disabled = this.disabled || false;

    this.searchControl.valueChanges
      .debounceTime(this.debounceTime)
      .distinctUntilChanged()
      .subscribe(value => {
        this.onSearch.emit(value);
      });
  }

  setCurrentValue(val) {
    this.currentValue = val[this.key];
    this.searchControl.reset();
    this.parentFormControl.patchValue(val);
  }

  addItem(item) {
    // remove element from the items list
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
    console.log('LAAAAAAAAAA');
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
