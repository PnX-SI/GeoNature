import { Component, OnInit, Input, ViewChild } from '@angular/core';
import { GeoJSON } from 'leaflet';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { SYNTHESE_CONFIG } from '../../synthese.config';
import { DataService } from '../../services/data.service';

@Component({
  selector: 'pnx-synthese-list',
  templateUrl: 'synthese-list.component.html',
  styleUrls: ['synthese-list.component.scss']
})
export class SyntheseListComponent implements OnInit {
  public SYNTHESE_CONFIG = SYNTHESE_CONFIG;
  public selectedObs: any;
  public previousRow: any;
  @Input() inputSyntheseData: GeoJSON;
  @ViewChild('table') table: any;
  constructor(public mapListService: MapListService, private _ds: DataService) {}

  ngOnInit() {}

  loadOneSyntheseReleve(event) {
    console.log(event);
    this._ds.getOneSyntheseObservation(event.value.id_synthese).subscribe(data => {
      this.selectedObs = data;
      console.log(data);
    });
  }

  toggleExpandRow(row) {
    if (this.previousRow) {
      this.table.rowDetail.toggleExpandRow(this.previousRow);
    }
    this.table.rowDetail.toggleExpandRow(row);
    this.previousRow = row;
  }
}
