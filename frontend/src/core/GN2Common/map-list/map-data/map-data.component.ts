import { Component, OnInit, ElementRef, ViewChild, Input, Output, OnChanges, EventEmitter, ViewEncapsulation } from '@angular/core';
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
  encapsulation: ViewEncapsulation.None
})
export class MapDataComponent implements OnInit, OnChanges {
  @ViewChild(DatatableComponent) table: DatatableComponent;
  @Input() allColumns: Array<any>;
  @Input() displayColumns: Array<any>;
  @Input() apiEndPoint: string;
  @Input() columnActions: ColumnActions;
  @Output() onDetail = new EventEmitter<number>();
  @Output() onEdit = new EventEmitter<number>();
  @Output() paramChanged = new EventEmitter<any>();
  @Output() pageChanged = new EventEmitter<any>();
  @Output() onDeleteRow = new EventEmitter<number>();
  filterList: Array<any>;
  filteredColumns: Array<any>;
  filterSelected: any;
  genericFilterInput = new FormControl();
  index = 0;


  selected = []; // list of row selected
  rows = []; // rows in data table

  constructor(
    private mapListService: MapListService,
    public ngbModal: NgbModal,
    private _commonService: CommonService
  ) {

  }

  ngOnInit() {
    this.filterList = [{'name': '', 'prop': ''}];

    this.filterSelected = {'name': '', 'prop': ''};

    

    this.mapListService.gettingTableId$.subscribe(res => {
      this.selected = []; // clear selected list
      for (const i in this.mapListService.tableData) {
        if (this.mapListService.tableData[i][this.mapListService.idName] === res) {
          this.selected.push(this.mapListService.tableData[i]);
        }
      }
    });


    this.mapListService.genericFilterInput.valueChanges
      .debounceTime(400)
      .distinctUntilChanged()
      .filter(value => value !== null)
      .subscribe(
        value => {
          if (value !== null && this.filterSelected.name === '') {
            this._commonService.translateToaster('warning', 'MapList.NoColumnSelected');
          } else {
            this.mapListService.urlQuery = this.mapListService.urlQuery.delete(this.filterSelected.prop);
            if (value.length > 0) {
              this.mapListService.refreshData(this.apiEndPoint, {param: this.filterSelected.prop, 'value': value});
            } else {
              this.mapListService.deleteAndRefresh(this.apiEndPoint, this.filterSelected.prop);
            }
          }
        });
  }

  onSelect(selected) {
    this.mapListService.setCurrentLayerId(this.selected[0][this.mapListService.idName]);
  }
  getRowClass() {
    return 'clickable';
  }


  toggle(col) {
    const isChecked = this.isChecked(col);

    if (isChecked) {
      this.displayColumns = this.displayColumns.filter(c => {
        return c.prop !== col.prop;
      });
    } else {
      this.displayColumns = [...this.displayColumns, col];
    }
  }


  isChecked(col) {
    let i = 0;
    while (i < this.displayColumns.length && this.displayColumns[i].prop !== col.prop) {
      i = i + 1;
    }
    return i === this.displayColumns.length ? false : true;
    }



  onChangeFilterOps(list) {
    // reset url query
    this.mapListService.urlQuery.delete(this.filterSelected.prop);
    this.filterSelected = list; // change filter selected
  }

  toggleExpandRow(row) {
    this.table.rowDetail.toggleExpandRow(row);
  }

  onEditReleve(idReleve) {
    this.onEdit.emit(idReleve);
  }

  onDetailReleve(idReleve) {
    this.onDetail.emit(idReleve);
  }


  setPage(pageInfo) {
    this.mapListService.page.pageNumber = pageInfo.offset;
    this.paramChanged.emit({param: 'offset', 'value': pageInfo.offset});
  }

  openDeleteModal(event, modal, iElement, row) {
    this.selected = [];
    this.selected.push(row);
    event.stopPropagation();
    // prevent erreur link to the component
    iElement && iElement.parentElement && iElement.parentElement.parentElement &&
    iElement.parentElement.parentElement.blur();
    this.ngbModal.open(modal);
  }

  deleteRow() {
    const deleteId = this.selected[0][this.mapListService.idName];
    // this.rows = this.rows.filter(row => {
    //   return row[this.mapListService.idName] !==  deleteId;
    // });
    // this.mapListService.page.totalElements = this.mapListService.page.totalElements -1 ;
    this.selected = [];

    this.onDeleteRow.emit(deleteId);
  }

  ngOnChanges(changes) {

    // init the columns
    if (changes.allColumns) {
      if (changes.allColumns.currentValue !== undefined ) {
        this.allColumns = changes.allColumns.currentValue;
        const doubleColumns = ['taxons', 'observateurs', 'date_min', 'date_max', 'leaflet_popup', 'observers'];
        this.filteredColumns = this.allColumns.filter(res => {
          return doubleColumns.indexOf(res.prop) === -1 ;
        });
      }
    }


  }
}




