import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { DataFormService } from '../data-form.service';


@Component({
  selector: 'pnx-observers',
  templateUrl: './observers.component.html',
  styleUrls: ['./observers.component.scss']
})
export class ObserversComponent implements OnInit {

  @Input()idMenu: number;
  @Input() placeholder: string;
  @Input() parentFormControl:FormControl;
  inputObservers: Array<any>;
  selectedObserver: string;
  selectedObservers: Array<string>;
  observerInput: FormControl;

  constructor(private _dfService: DataFormService) {
   }

  ngOnInit() {
    this.selectedObservers = [];
    this._dfService.getObservers(this.idMenu)
      .subscribe(data => this.inputObservers = data);
    
  }

  // onAddObserver() {
  //   this.observerSelected.emit(this.selectedObserver);
  // }

}
