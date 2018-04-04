import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { DataFormService } from '../data-form.service';
import { Observable } from 'rxjs/Observable';

@Component({
  selector: 'pnx-observers',
  templateUrl: './observers.component.html',
  styleUrls: ['./observers.component.scss'],
  encapsulation: ViewEncapsulation.None
})
export class ObserversComponent implements OnInit {
  filteredObservers: Array<any>;
  @Input() idMenu: number;
  @Input() label: string;
  @Input() disabled: boolean;
  @Input() parentFormControl: FormControl;
  @Output() onChange = new EventEmitter<any>();
  @Output() onDelete = new EventEmitter<any>();
  public searchControl = new FormControl();
  public observers: Array<any>;
  public selectedObservers = [];

  constructor(private _dfService: DataFormService) {}

  ngOnInit() {
    this.selectedObservers = [];
    this._dfService.getObservers(this.idMenu).subscribe(data => {
      this.observers = data;
      this.filteredObservers = data;
    });
  }

  filterObservers(event) {
    if (event !== null) {
      this.filteredObservers = this.observers.filter(obs => {
        return obs.nom_complet.toLowerCase().indexOf(event.toLowerCase()) === 0;
      });
    }
  }
  addObserver(obs) {
    this.observers = this.observers.filter(observer => {
      return observer.id_role !== obs.id_role;
    });
    this.selectedObservers.push(obs);
    this.searchControl.reset();
    this.parentFormControl.patchValue(this.selectedObservers);
    this.onChange.emit(obs);
  }

  removeObserver(obs) {
    this.observers.push(obs);
    this.selectedObservers = this.selectedObservers.filter(selectObs => {
      return selectObs.id_role !== obs.id_role;
    });
    this.parentFormControl.patchValue(this.selectedObservers);
    this.onDelete.emit(obs);
  }
}
