import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import {FormService} from '../service/form.service';

@Component({
  selector: 'app-nomenclature',
  templateUrl: './nomenclature.component.html',
  styleUrls: ['./nomenclature.component.scss']
})
export class NomenclatureComponent implements OnInit {
  labels:any;
  selectedId:number;
  @Input() placeholder:string;
  @Input() id_nomenclature:number;
  @Input() regne:string;
  @Input() group2_inpn:string;
  @Input() lang:string;
  @Output('labelSelected') emitter = new EventEmitter<number>();
  constructor(private _formService:FormService) { }

  ngOnInit() {
    this.labels = this._formService.getNomenclature(this.id_nomenclature, this.regne, this.group2_inpn);
  }

  ngOnChanges(){
    // todo
    // when input language change, change which values are display
  }

}
