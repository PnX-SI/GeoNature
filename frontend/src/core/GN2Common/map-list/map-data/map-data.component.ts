import { Component, OnInit, ElementRef, ViewChild, Input, OnChanges } from '@angular/core';
import { MapService } from '../../map/map.service';
import { MapListService } from '../../map-list/map-list.service';
import { DatatableComponent } from '@swimlane/ngx-datatable';


@Component({
  selector: 'pnx-map-data',
  templateUrl: './map-data.component.html',
  styleUrls: ['./map-data.component.scss']
})
export class MapDataComponent implements OnInit, OnChanges {
  @ViewChild(DatatableComponent) table: DatatableComponent;
  @Input() tableData: Array<any>;


  // colums on datatable
  columns = [
    { prop: 'taxon' },
    { prop: 'observer' },
    { prop: 'date' }
  ];

  filterList = [...this.columns.map(res => res.prop)];
  filterSelected = this.filterList[0];

  selected = []; // list of row selected
  //releves = []; // cache our list in releves use for filter
  rows = []; // rows in data table

  constructor(private _mapListService: MapListService) {

    this._mapListService.gettingTableId$.subscribe(res => {
      this.selected = []; // clear selected list
      for (const i in this.tableData) {
        if (this.tableData[i].id === res) {
          this.selected.push(this.tableData[i]);
        }
      }
    });
  }

  ngOnInit() {
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
    // TODO
    // console.log(idReleve);
  }

  ngOnChanges(changes){
    if(changes.tableData.currentValue !== undefined){
      this.rows = changes.tableData.currentValue;      
    }
      
    
  }
}


