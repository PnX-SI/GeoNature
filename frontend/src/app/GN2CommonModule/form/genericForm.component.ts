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
  @Output() onChange = new EventEmitter<any>();
  @Output() onDelete = new EventEmitter<any>();
  public sub: Subscription;

  constructor() {}

  ngOnInit() {}

  ngAfterViewInit() {
    if (!this.debounceTime) {
      this.debounceTime = 0;
    }
    this.sub = this.parentFormControl.valueChanges
      .distinctUntilChanged()
      .debounceTime(this.debounceTime)
      .subscribe(value => {
        if (!value || (value && (value.length === 0 || value === ''))) {
          this.onDelete.emit();
        } else {
          console.log('change');
          this.onChange.emit(value);
        }
      });
  }

  ngOnDestroy() {
    this.sub.unsubscribe();
  }
}
