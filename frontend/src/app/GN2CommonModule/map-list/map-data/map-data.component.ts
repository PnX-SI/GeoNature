import { Component, OnInit, ElementRef, ViewChild, Input, Output, OnChanges, EventEmitter } from '@angular/core';
import { MapService } from '../../map/map.service';
import { MapListService } from '../../map-list/map-list.service';
import { DatatableComponent } from '@swimlane/ngx-datatable';
import { FormControl } from '@angular/forms';
import {NgbModal, ModalDismissReasons} from '@ng-bootstrap/ng-bootstrap';
import { CommonService } from '@geonature_common/service/common.service';
import { ColumnActions } from '@geonature_common/map-list/map-list.component';



@Component({
  selector: 'pnx-map-data',
  templateUrl: './map-data.component.html',
  styleUrls: ['./map-data.component.scss'],
})
export class MapDataComponent implements OnInit {
  @ViewChild(DatatableComponent) table: DatatableComponent;
  @Input() apiEndPoint: string;
  @Output() paramChanged = new EventEmitter<any>();
  @Output() pageChanged = new EventEmitter<any>();


  index = 0;
  rows = []; // rows in data table

  constructor(
    public mapListService: MapListService,
    public ngbModal: NgbModal,
    private _commonService: CommonService
  ) {

  }

  ngOnInit() {

  }

  toggleExpandRow(row) {
    this.table.rowDetail.toggleExpandRow(row);
  }



}




