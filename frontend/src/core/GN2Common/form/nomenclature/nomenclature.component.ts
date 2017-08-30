import { Component, OnInit, Input, Output, EventEmitter, OnChanges, SimpleChanges } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { FormService } from '../form.service';

@Component({
  selector: 'pnx-nomenclature',
  templateUrl: './nomenclature.component.html',
  styleUrls: ['./nomenclature.component.scss']
})
export class NomenclatureComponent implements OnInit, OnChanges {
  labels: any[];
  nomenclature: any;
  selectedId: number;
  @Input() placeholder: string;
  @Input() parentFormControl: FormGroup;
  @Input() idTypeNomenclature: number;
  @Input() regne: string;
  @Input() group2Inpn: string;
  @Input() lang: string;
  @Output() valueSelected = new EventEmitter<any>();
  constructor(private _formService: FormService) { }


  ngOnInit() {    
    // load the data
     this._formService.getNomenclature(this.idTypeNomenclature, this.regne, this.group2Inpn)
      .subscribe(data => this.labels = data.values);
    
  }

  ngOnChanges(changes: SimpleChanges) {
    // if change regne => change groupe2inpn also
    if (changes.regne !== undefined && !changes.regne.firstChange) {
      this._formService.getNomenclature(this.idTypeNomenclature, changes.regne.currentValue, changes.group2Inpn.currentValue)
        .subscribe(data => this.labels = data.values);
    }
    // if only change groupe2inpn
    if (changes.regne === undefined && changes.group2Inpn !== undefined && !changes.group2Inpn.firstChange) {
        this._formService.getNomenclature(this.idTypeNomenclature, this.regne, this.group2Inpn)
          .subscribe(data => this.labels = data.values);
      }
    }

  // Output
  onLabelChange() {
    this.valueSelected.emit(this.selectedId);
  }
}
