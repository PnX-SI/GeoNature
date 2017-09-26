import { Component, OnInit, ElementRef, ViewChild, Input, OnChanges } from '@angular/core';
import { MapService } from '../../map/map.service';
import { MapListService } from '../../map-list/map-list.service';
import { DatatableComponent } from '@swimlane/ngx-datatable';
import { Router } from '@angular/router';

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
  filterList: Array<any>;
  filterSelected: any;

  selected = []; // list of row selected
  rows = []; // rows in data table

  // tslint:disable-next-line
  //myDatas = 
  constructor(private _mapListService: MapListService, private _router: Router) {
  }

  ngOnInit() {
    this.filterList = [...this.columns.map(res => res.prop)];
    this.filterSelected = this.filterList[0];

    this._mapListService.gettingTableId$.subscribe(res => {
      this.selected = []; // clear selected list
      for (const i in this.tableData) {
        if (this.tableData[i].id === res) {
          this.selected.push(this.tableData[i]);
        }
      }
    });
  }

  onSelect({ selected }) {
    this._mapListService.setCurrentLayerId(this.selected[0].id);
  }

  updateFilter(event) {

    const val = event.target.value.toLowerCase();

    // filter our data
    const temp = this.tableData.filter(res => {
      return res[this.filterSelected].toLowerCase().indexOf(val) !== -1 || !val;
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

  ngOnChanges(changes) {
    // init the rows
    if (changes.tableData.currentValue !== undefined) {
      this.rows = changes.tableData.currentValue;
    }
  }
}


