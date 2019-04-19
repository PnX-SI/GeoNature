import { Component, OnInit, Input, ViewEncapsulation } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { DataFormService } from '../data-form.service';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Component({
  selector: 'pnx-observers',
  templateUrl: './observers.component.html',
  styleUrls: ['./observers.component.scss'],
  encapsulation: ViewEncapsulation.None
})
export class ObserversComponent implements OnInit {
  @Input() idMenu: number;
  @Input() label: string;
  // Disable the input: default to false
  @Input() disabled = false;
  @Input() parentFormControl: FormControl;
  // display the value 'Tous' on the value list - default = false
  @Input() bindAllItem = false;
  // search bar default to true
  @Input() searchBar = true;

  public observers: Observable<Array<any>>;

  constructor(private _dfService: DataFormService) {}

  ngOnInit() {
    this.disabled ? this.parentFormControl.enable() : this.parentFormControl.disable();

    this.observers = this._dfService
                          .getObservers(this.idMenu)
                          .pipe(
                            map(data => data)
                          );
  }
}
