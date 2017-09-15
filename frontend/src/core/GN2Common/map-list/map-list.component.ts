import { Component, OnInit} from '@angular/core';
import { MapService } from '../map/map.service';
import {MapListService} from '../map-list/map-list.service';


@Component({
  selector: 'pnx-map-list',
  templateUrl: './map-list.component.html',
  styleUrls: ['./map-list.component.scss'],
  providers: [MapService, MapListService]
})
export class MapListComponent implements OnInit {
  public geojson: any;
  constructor(private _ms: MapService, private _mapListService: MapListService) {
  }

  ngOnInit() {
    this._mapListService.getReleves()
      .subscribe(res => this.geojson = res);
  }
}
