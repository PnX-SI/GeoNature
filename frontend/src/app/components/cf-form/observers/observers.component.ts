import { Component, OnInit, Input } from '@angular/core';
import {FormService} from '../service/form.service';

@Component({
  selector: 'app-observers',
  templateUrl: './observers.component.html',
  styleUrls: ['./observers.component.scss']
})
export class ObserversComponent implements OnInit {

  @Input()idMenu: number;
  @Input() placeholder: string;
  observers: Array<any>;

  constructor(private _formService: FormService) { }

  ngOnInit() {
    this._formService.getObservers(this.idMenu)
      .then(d => {
        this.observers = d;
      });
  }

}
