import {
  Component,
  OnInit,
  Input,
  Output,
  EventEmitter,
  AfterViewInit,
  OnDestroy
} from '@angular/core';
import { FormControl } from '@angular/forms';
import { Subscription } from 'rxjs/Subscription';

@Component({})
export class GenericFormComponent implements OnInit, AfterViewInit, OnDestroy {
  @Input() parentFormControl: FormControl;
  @Input() label: string;
  @Input() disabled: boolean;
  @Input() debounceTime: number;
  @Input() multiSelect: boolean;
  @Input() searchBar: boolean;
  @Input() displayAll: false; // param to display the field 'all' in the list, default at false
  @Output() onChange = new EventEmitter<any>();
  @Output() onDelete = new EventEmitter<any>();
  public sub: Subscription;

  constructor() {}

  ngOnInit() {
    this.disabled = this.disabled || false;
    this.searchBar = this.searchBar || false;
    this.multiSelect = this.multiSelect || false;
    this.debounceTime = this.debounceTime || 0;
  }

  ngAfterViewInit() {
    this.sub = this.parentFormControl.valueChanges
      .distinctUntilChanged()
      .debounceTime(this.debounceTime)
      .subscribe(value => {
        if (!value || (value && (value.length === 0 || value === ''))) {
          this.onDelete.emit();
        } else {
          this.onChange.emit(value);
        }
      });
  }

  ngOnDestroy() {
    this.sub.unsubscribe();
  }
}
