import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import {FormService} from '../service/form.service';

@Component({
  selector: 'app-nomenclature',
  templateUrl: './nomenclature.component.html',
  styleUrls: ['./nomenclature.component.scss']
})
export class NomenclatureComponent implements OnInit {
  labels: any[];
  selectedId: number;
  @Input() placeholder: string;
  @Input() idNomenclature: number;
  @Input() regne: string;
  @Input() group2Inpn: string;
  @Input() lang: string;
  @Output('labelSelected') emitter = new EventEmitter<number>();
  constructor(private _formService:FormService) { }

  ngOnInit() {
     this._formService.getNomenclature(this.idNomenclature, this.regne, this.group2Inpn).then(
      data => {
        this.labels = data;
      }
    );
  }



  ngOnChanges(){
    // todo
    // when input language change, change which values are display
  }

}
