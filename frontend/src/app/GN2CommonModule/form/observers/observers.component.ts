import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { DataFormService } from '../data-form.service';
import { Observable, BehaviorSubject } from 'rxjs';
import { map } from 'rxjs/operators';

@Component({
  selector: 'pnx-observers',
  templateUrl: './observers.component.html',
  styleUrls: ['./observers.component.scss'],
  encapsulation: ViewEncapsulation.None
})
export class ObserversComponent implements OnInit {
  observersCache: Array<any>;
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
  public select2Value: Observable<string[]>;

  constructor(private _dfService: DataFormService) {}

  ngOnInit() {
    this.observers = this._dfService
                          .getObservers(this.idMenu)
                          .pipe(
                            map(data => {
                              this.observersCache = data;
                              return data;
                            })
                          );
    this.select2Value = this.parentFormControl
                            .valueChanges
                            .pipe(
                              map(
                                (res: Array<any>) => {
                                  return res.map(val => val['id_role'].toString())
                              })
                            ); 
  }

  /**
  *  permet de convertir le tableau de valeur renvoyé par le select2 en observaters Object
  **/
  onChange(value) {
    this.parentFormControl.setValue(
      this.observersCache.filter(obs => value.includes(obs.id_role.toString()))
    );
  }
}
