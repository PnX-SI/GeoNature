import { Component, OnInit, Input } from '@angular/core';
import {FormService} from '../service/form.service';

@Component({
  selector: 'app-nomenclature',
  templateUrl: './nomenclature.component.html',
  styleUrls: ['./nomenclature.component.scss']
})
export class NomenclatureComponent implements OnInit {
  labels:any;
  selectedId:number;
  @Input() id_nomenclature:number;
  @Input() cd_nom:number;
  @Input() lang:string;
  constructor(private _formService:FormService) { }

  ngOnInit() {
    this.labels = this._formService.getNomenclature(1, 212, 'fr');
  }

}
