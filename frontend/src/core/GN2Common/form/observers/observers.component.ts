import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { DataFormService } from '../data-form.service';
import { Observable } from 'rxjs/Observable';

@Component({
  selector: 'pnx-observers',
  templateUrl: './observers.component.html',
  styleUrls: ['./observers.component.scss']
})
export class ObserversComponent implements OnInit {

  filteredObservers: Array<any>;
  @Input()idMenu: number;
  @Input() placeholder: string;
  @Input() parentFormControl:FormControl;
  observers: Array<any>;
  selectedObservers: Array<string>;

  constructor(private _dfService: DataFormService) {
   }

  ngOnInit() {
    this.selectedObservers = [];
    this._dfService.getObservers(this.idMenu)
      .subscribe(data => this.observers = data);
  }

  filterObservers(event){
    const query = event.query;
    this.filteredObservers = this.observers.filter(obs => {
      return obs.nom_complet.toLowerCase().indexOf(query.toLowerCase()) === 0
    })
  }
  addObservers(observer){    
    this.selectedObservers.push(observer.id_role)
    this.parentFormControl.patchValue(this.selectedObservers);
  }
  removeObservers(observer){
    const index = this.selectedObservers.indexOf(observer.id_role)
    this.selectedObservers.splice(index, 1);
    this.parentFormControl.patchValue(this.selectedObservers);
  }

    


}
