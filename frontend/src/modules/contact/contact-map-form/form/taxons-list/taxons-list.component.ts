import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';

@Component({
  selector: 'pnx-taxons-list',
  templateUrl: './taxons-list.component.html',
  styleUrls: ['./taxons-list.component.scss']
})
export class TaxonsListComponent implements OnInit {
  @Input() list: Array<any>;
  @Output() taxonRemoved = new EventEmitter<number>();
  @Output() taxonEdited = new EventEmitter<number>();

  constructor() { }

  ngOnInit() {
  }
  deleteTaxon(index): void {
    this.taxonRemoved.emit(index);
  }
  editTaxons(index): void {
    this.taxonEdited.emit(index);
  }


}
