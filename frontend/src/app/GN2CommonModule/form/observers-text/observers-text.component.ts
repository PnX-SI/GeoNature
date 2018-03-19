import { Component, OnInit, Output, Input, EventEmitter } from '@angular/core';
import {FormControl} from '@angular/forms';

@Component({
  selector: 'pnx-observers-text',
  templateUrl: 'observers-text.component.html',
  styleUrls: ['./observers-text.component.scss']
})

export class ObserversTextComponent implements OnInit {
  @Input() parentFormControl: FormControl;
  @Input() disabled: boolean;
  @Output() onObserverChange = new EventEmitter<string>();
  @Output() onObserverDelete = new EventEmitter();
  constructor() { }

  ngOnInit() {
    this.parentFormControl.valueChanges
    .debounceTime(600)
    .distinctUntilChanged()
    .subscribe(value => {
      if (value && value.length > 0) {
        this.onObserverChange.emit(value);
      } else {
        this.onObserverDelete.emit();
      }
    });
   }
}
