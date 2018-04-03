import { Component, OnInit, Input, EventEmitter, Output } from '@angular/core';
import { FormControl } from '@angular/forms';

@Component({
  selector: 'pnx-select-search',
  templateUrl: './select-search.component.html',
  styleUrls: ['./select-search.component.scss']
})
export class SelectSearchComponent implements OnInit {
  public currentValue: any;
  public searchControl = new FormControl();
  @Input() parentFormControl: FormControl;
  // value of the options
  @Input() values: Array<any>;
  // key of the array of options
  @Input() key: string;
  @Input() label: any;
  @Input() debounceTime: number;
  @Output() onSearch = new EventEmitter();
  constructor() {}

  ngOnInit() {
    this.debounceTime = this.debounceTime || 100;
    this.searchControl.valueChanges
      .debounceTime(this.debounceTime)
      .distinctUntilChanged()
      .subscribe(value => {
        this.onSearch.emit(value);
      });
  }

  setCurrentValue(val) {
    this.currentValue = val[this.key];
    this.parentFormControl.patchValue(val);
  }
}
