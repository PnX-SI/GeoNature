import { Component, OnInit, Input, EventEmitter } from '@angular/core';

@Component({
  selector: 'app-taxons-list',
  templateUrl: './taxons-list.component.html',
  styleUrls: ['./taxons-list.component.scss']
})
export class TaxonsListComponent implements OnInit {
  @Input() list: Array<any>;
  // @Output
  constructor() { }

  ngOnInit() {
  }


}
