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
  // Disable the input: default to false
  @Input() disabled = false;
  @Input() parentFormControl: FormControl;
  // display the value 'Tous' on the value list - default = false
  @Input() bindAllItem = false;
  // search bar default to true
  @Input() searchBar = true;
  @Output() onChange = new EventEmitter<any>();
  @Output() onDelete = new EventEmitter<any>();
  public searchControl = new FormControl();
  public observers: Array<any>;
  public selectedObservers = [];

  constructor(private _dfService: DataFormService) {}

  ngOnInit() {
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
}
