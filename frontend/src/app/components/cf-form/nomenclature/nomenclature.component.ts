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

  // loadNomenclature(idNomenclature, regne, group2Inpn): any {
  //   let labels = {};
  //   this._formService.getNomenclature(this.idNomenclature, this.regne, this.group2Inpn).then(
  //     data => {
  //       labels = data.values;
  //     }
  //   );
  //   return labels;
  // }

  ngOnInit() {
    // this.labels = this.loadNomenclature(this.idNomenclature, this.regne, this.group2Inpn);
     this._formService.getNomenclature(this.idNomenclature, this.regne, this.group2Inpn)
      .subscribe(data => this.labels = data.values);
  }

  ngOnChanges(changes: SimpleChanges) {
    // if change regne => change groupe2inpn also
    if (changes.regne !== undefined && !changes.regne.firstChange) {
      this._formService.getNomenclature(this.idNomenclature, changes.regne.currentValue, changes.group2Inpn.currentValue)
        .subscribe(data => this.labels = data.values);
    }
    // if only change groupe2inpn
    if (changes.regne === undefined && changes.group2Inpn !== undefined && !changes.group2Inpn.firstChange) {
        this._formService.getNomenclature(this.idNomenclature, this.regne, this.group2Inpn)
          .subscribe(data => this.labels = data.values);
      }
    }

  // Output
  onLabelChange() {
    this.labelSelected.emit(this.selectedId);
  }


}
