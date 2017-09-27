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
  @Input() columns: Array<any>;
  @Input() pathRedirect: string;
  @Output() paramChanged = new EventEmitter<any>();
  @Output() pageChanged = new EventEmitter<any>();
  filterList: Array<any>;
  filterSelected: any;
  inputTaxon = new FormControl();
  inputObservers = new FormControl();
  dateMin = new FormControl();
  dateMax = new FormControl();


  selected = []; // list of row selected
  rows = []; // rows in data table

  constructor(private mapListService: MapListService, private _router: Router) {

  }

  ngOnInit() {
    this.filterList = this.columns;

    this.filterSelected = this.filterList[0];

    this.mapListService.gettingTableId$.subscribe(res => {
      this.selected = []; // clear selected list
      for (const i in this.tableData) {
        if (this.tableData[i].id === res) {
          this.selected.push(this.tableData[i]);
        }
      }
    });

    this.dateMin.valueChanges.subscribe(res => {
      console.log(res);
    });
  }

  onSelect({ selected }) {
    this.mapListService.setCurrentLayerId(this.selected[0].id);
  }

  updateFilter(event) {

    const val = event.target.value.toLowerCase();

    // filter our data
    const temp = this.tableData.filter(res => {
      return res[this.filterSelected.prop].toLowerCase().indexOf(val) !== -1 || !val;
    });

    // update the rows
    this.rows = temp;
    // whenever the filter changes, always go back to the first page
    this.table.offset = 0;
  }

  onChangeFilterOps(list) {
    this.filterSelected = list; // change filter selected
  }

  toggleExpandRow(row) {
    this.table.rowDetail.toggleExpandRow(row);
  }

  onEditReleve(idReleve) {
    this._router.navigate(['contact-form', idReleve]);
  }

  onDetailReleve(id_releve) {
    // TODO
  }

  redirect() {
    this._router.navigate([this.pathRedirect]);
  }

  taxonChanged(taxonObj) {
    // refresh taxon in url query
    this.mapListService.urlQuery.delete('cd_nom');
    this.paramChanged.emit({param: 'cd_nom', 'value': taxonObj.cd_nom});
  }
  observerChanged(observer) {
    console.log(observer);
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
    this.paramChanged.emit({param: 'date_up', 'value': date});
  }
  dateMaxChanged(date) {
    this.mapListService.urlQuery.delete('date_low');
    this.paramChanged.emit({param: 'date_low', 'value': date});
  }

  setPage(pageInfo) {
    this.mapListService.page.pageNumber = pageInfo.offset;
    this.paramChanged.emit({param: 'offset', 'value': pageInfo.offset});
  }
  ngOnChanges(changes) {
    // init the rows
    if (changes.tableData.currentValue !== undefined) {
      this.rows = changes.tableData.currentValue;
    }
  }
}




