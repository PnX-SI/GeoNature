import { Component, OnInit, Input, ViewChild, HostListener, OnChanges } from '@angular/core';
import { GeoJSON } from 'leaflet';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { SYNTHESE_CONFIG } from '../../synthese.config';
import { DataService } from '../../services/data.service';
import { window } from 'rxjs/operator/window';

@Component({
  selector: 'pnx-synthese-list',
  templateUrl: 'synthese-list.component.html',
  styleUrls: ['synthese-list.component.scss']
})
export class SyntheseListComponent implements OnInit, OnChanges {
  public SYNTHESE_CONFIG = SYNTHESE_CONFIG;
  public selectedObs: any;
  public previousRow: any;
  public rowNumber: number;
  @Input() inputSyntheseData: GeoJSON;
  @ViewChild('table') table: any;
  constructor(public mapListService: MapListService, private _ds: DataService) {}

  ngOnInit() {
    // Au clique sur la carte, selection dans la liste
    this.mapListService.onMapClik$.subscribe(id => {
      this.mapListService.selectedRow = []; // clear selected list

      const integerId = parseInt(id);
      // const integerId = parseInt(id);
      let i;
      for (i = 0; i < this.mapListService.tableData.length; i++) {
        if (this.mapListService.tableData[i]['id_synthese'] === integerId) {
          this.mapListService.selectedRow.push(this.mapListService.tableData[i]);
          break;
        }
      }
      const page = Math.trunc(i / 10);
      this.table.offset = page;
    });

    // get wiewport height to set the number of rows in the table
    const h = document.documentElement.clientHeight;
    this.rowNumber = Math.trunc(h / 62);
  }

  @HostListener('window:resize', ['$event'])
  onResize(event) {
    this.rowNumber = Math.trunc(event.target.innerHeight / 62);
  }

  loadOneSyntheseReleve(event) {
    this._ds.getOneSyntheseObservation(event.value.id_synthese).subscribe(data => {
      this.selectedObs = data;
    });
  }

  toggleExpandRow(row) {
    if (this.previousRow) {
      this.table.rowDetail.toggleExpandRow(this.previousRow);
    }
    this.table.rowDetail.toggleExpandRow(row);
    this.previousRow = row;
  }

  ngOnChanges(changes) {
    if (changes && changes.inputSyntheseData.currentValue) {
      // reset page 0 when new data appear
      this.table.offset = 0;
    }
  }
}
