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
import { Subscription } from 'rxjs';

@Component({
  selector: 'pnx-generic-form',
  template: ''
})
export class GenericFormComponent implements OnInit, AfterViewInit, OnDestroy {
  @Input() parentFormControl: FormControl;
  @Input() label: string;
  @Input() disabled: boolean = false;
  @Input() debounceTime: number;
  @Input() multiSelect: boolean = false;
  @Input() searchBar: boolean = false;
  @Input() displayAll: boolean = false; // param to display the field 'all' in the list, default at false
  @Output() onChange = new EventEmitter<any>();
  @Output() onDelete = new EventEmitter<any>();
  public sub: Subscription;

  constructor() {}

  ngOnInit() {
    this.disabled ? this.parentFormControl.enable() : this.parentFormControl.disable();
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

  filterItems(event, savedItems, itemKey) {
    if (this.searchBar && event) {
      return savedItems.filter(el => {
        const isIn = el[itemKey].toUpperCase().indexOf(event.toUpperCase());
        return isIn !== -1;
      });
    } else {
      return savedItems;
    }
  }

  ngOnDestroy() {
    this.sub.unsubscribe();
  }
}
