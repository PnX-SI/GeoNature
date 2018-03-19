import { Component, OnInit, Input, Output, EventEmitter, AfterViewInit } from '@angular/core';
import { FormControl } from '@angular/forms';

@Component({})
export class GenericFormComponent implements OnInit, AfterViewInit {
  @Input() parentFormControl: FormControl;
  @Input() label: string;
  @Input() disabled: boolean;
  @Input() debounceTime: number;
  @Output() onChange = new EventEmitter<any>();
  @Output() onDelete = new EventEmitter<any>();

  constructor() {
    console.log('init generic');
  }

  ngOnInit() {}

  ngAfterViewInit() {
    if (!this.debounceTime) {
      console.log('no debouncetime');
      this.debounceTime = 0;
    }
    this.parentFormControl.valueChanges
      .distinctUntilChanged()
      .debounceTime(this.debounceTime)
      .subscribe(value => {
        if (value && (value.length === 0 || value === '')) {
          console.log('delete');
          this.onDelete.emit();
        } else {
          this.onChange.emit(value);
          console.log('change');
          console.log(value);
        }
      });
  }
}
