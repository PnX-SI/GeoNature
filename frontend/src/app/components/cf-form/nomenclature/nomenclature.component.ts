import { Component, OnInit, Input, Output, EventEmitter, OnChanges, SimpleChanges } from '@angular/core';
import {FormService} from '../service/form.service';

@Component({
  selector: 'app-nomenclature',
  templateUrl: './nomenclature.component.html',
  styleUrls: ['./nomenclature.component.scss']
})
export class NomenclatureComponent implements OnInit, OnChanges {
  labels: any[];
  nomenclature: any;
  selectedId: number;
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

  ngOnChanges(changes: SimpleChanges) {
    if (changes.regne && changes.group2Inpn) {
      this._formService.getNomenclature(this.idNomenclature, changes.regne.currentValue, changes.group2Inpn.currentValue)
        .then(data =>  {
          this.labels = data.values;
          this.nomenclature = data.mnemonique;
        });
    }
  }
  onLabelChange() {
    this.labelSelected.emit(this.selectedId);
  }



  // ngOnChanges(){
    // TODO
    // when input language change, change which values are display
  // }

}
