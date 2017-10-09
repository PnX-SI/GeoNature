import { Component, OnInit, ElementRef, ViewChild, Input, Output, OnChanges, EventEmitter } from '@angular/core';
import { MapService } from '../../map/map.service';
import { MapListService } from '../../map-list/map-list.service';
import { DatatableComponent } from '@swimlane/ngx-datatable';
import { Router } from '@angular/router';
import { FormControl } from '@angular/forms';


@Component({
  selector: 'pnx-map-data',
  templateUrl: './map-data.component.html',
  styleUrls: ['./map-data.component.scss']
})
export class MapDataComponent implements OnInit, OnChanges {
  @ViewChild(DatatableComponent) table: DatatableComponent;
  @Input() tableData: Array<any>;
  @Input() allColumns: Array<any>;
  @Input() displayColumns: Array<any>;
  @Input() pathInfo: string;
  @Input() pathEdit: string;
  @Output() paramChanged = new EventEmitter<any>();
  @Output() pageChanged = new EventEmitter<any>();
  @Output() paramDeleted = new EventEmitter<any>();
  filterList: Array<any>;
  filterSelected: any;
  inputTaxon = new FormControl();
  inputObservers = new FormControl();
  dateMin = new FormControl();
  dateMax = new FormControl();
  genericFilter = new FormControl();
  index = 0;


  selected = []; // list of row selected
  rows = []; // rows in data table

  constructor(private mapListService: MapListService, private _router: Router) {

  }

  ngOnInit() {
    this.filterList = [{'name': '', 'prop': ''}];

    this.filterSelected = {'name': '', 'prop': ''};

    this.mapListService.gettingTableId$.subscribe(res => {
      this.selected = []; // clear selected list
      for (const i in this.tableData) {
        if (this.tableData[i].id === res) {
          this.selected.push(this.tableData[i]);
        }
      }
    });


    this.genericFilter.valueChanges
      .debounceTime(400)
      .distinctUntilChanged()
      .subscribe(value => {
        this.mapListService.urlQuery.delete(this.filterSelected.prop);
        if (value.length > 0) {
          this.paramChanged.emit({param: this.filterSelected.prop, 'value': value});
        } else {
          this.paramChanged.emit({param: '', 'value': ''});
        }
      });
  }

  onSelect({ selected }) {
    this.mapListService.setCurrentLayerId(this.selected[0][this.mapListService.idName]);
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
    this._router.navigate([this.pathEdit, idReleve]);
  }

  onDetailReleve(idReleve) {
    this._router.navigate([this.pathInfo, idReleve]);
  }

  redirect() {
    this._router.navigate([this.pathEdit]);
  }

  deleteAndRefresh(param) {
    this.mapListService.urlQuery.delete(param);
    this.paramDeleted.emit();
  }

  taxonChanged(taxonObj) {
    // refresh taxon in url query
    this.mapListService.urlQuery.delete('cd_nom');
    this.paramChanged.emit({param: 'cd_nom', 'value': taxonObj.cd_nom});
  }

  observerChanged(observer) {
     this.paramChanged.emit({param: 'observer', 'value': observer.id_role});
  }

  observerDeleted(observer) {
    const idObservers = this.mapListService.urlQuery.getAll('observer');
    idObservers.splice(idObservers.indexOf(observer.id_role));
    idObservers.forEach(id => {
      this.mapListService.urlQuery.set('observer', id);
    });
  }

  dateMinChanged(date) {
    this.mapListService.urlQuery.delete('date_up');
    if (date.length > 0) {
      this.paramChanged.emit({param: 'date_up', 'value': date});
    }
  }
  dateMaxChanged(date) {
    this.mapListService.urlQuery.delete('date_low');
    if (date.length > 0) {
      this.paramChanged.emit({param: 'date_low', 'value': date});
    }
  }

  setPage(pageInfo) {
    this.mapListService.page.pageNumber = pageInfo.offset;
    this.paramChanged.emit({param: 'offset', 'value': pageInfo.offset});
  }
  ngOnChanges(changes) {
    // init the rows
    if (changes.tableData) {
      if (changes.tableData.currentValue !== undefined) {
        this.rows = changes.tableData.currentValue;
      }
    }
    // init the columns
    if (changes.allColumns) {
      if (changes.allColumns.currentValue !== undefined ) {
        this.allColumns = changes.allColumns.currentValue;
      }
    }


  }
}




