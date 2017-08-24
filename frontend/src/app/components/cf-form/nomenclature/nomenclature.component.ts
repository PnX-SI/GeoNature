import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import {FormService} from '../service/form.service';

@Component({
  selector: 'app-nomenclature',
  templateUrl: './nomenclature.component.html',
  styleUrls: ['./nomenclature.component.scss']
})
export class NomenclatureComponent implements OnInit {
  labels: any[];
  nomenclature: any;
  selectedId: number;
  selectedLabel: any;
  @Input() placeholder: string;
  @Input() idNomenclature: number;
  @Input() regne: string;
  @Input() group2Inpn: string;
  @Input() lang: string;
  @Output() labelSelected = new EventEmitter<any>();
  constructor(private _formService: FormService) { }

  ngOnInit() {
     this._formService.getNomenclature(this.idNomenclature, this.regne, this.group2Inpn).then(
      data => {
        this.labels = data.values;
        this.nomenclature = data.mnemonique;
      }
    );
  }

  onLabelChange() {
    this.labelSelected.emit({nomenclature: this.nomenclature, idLabel: this.selectedLabel});
  }



  // ngOnChanges(){
    // TODO
    // when input language change, change which values are display
  // }

}
