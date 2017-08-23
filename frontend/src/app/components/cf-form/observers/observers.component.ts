import { Component, OnInit, Input } from '@angular/core';
import {FormService} from '../service/form.service';

@Component({
  selector: 'app-observers',
  templateUrl: './observers.component.html',
  styleUrls: ['./observers.component.scss']
})
export class ObserversComponent implements OnInit {

  @Input()id_module: number;
  observers:Array<any>;

  constructor(private _formService:FormService) { }

  ngOnInit() {
    //this.formService.getObservers(this.id_module);
  }

}
