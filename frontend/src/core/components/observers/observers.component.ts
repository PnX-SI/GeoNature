import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { FormService } from '../../services/form.service';

@Component({
  selector: 'app-observers',
  templateUrl: './observers.component.html',
  styleUrls: ['./observers.component.scss']
})
export class ObserversComponent implements OnInit {

  @Input()idMenu: number;
  @Input() placeholder: string;
  @Output() observerSelected = new EventEmitter<string>();
  @Output() obseverDeleted = new EventEmitter<string>();
  inputObservers: Array<any>;
  selectedObserver: string;
  selectedObservers: Array<string>;

  constructor(private _formService: FormService) { }

  ngOnInit() {
    this.selectedObservers = [];
    this._formService.getObservers(this.idMenu)
      .subscribe(data => this.inputObservers = data);
  }

  onAddObserver() {
    this.observerSelected.emit(this.selectedObserver);
  }

  onDeleteObserver() {
    // TODO
    // this.obseverDeleted.emit(observer);
  }
}
