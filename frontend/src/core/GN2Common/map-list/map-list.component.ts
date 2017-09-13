import { Component, OnInit} from '@angular/core';
import { MapService } from '../map/map.service';


@Component({
  selector: 'pnx-map-list',
  templateUrl: './map-list.component.html',
  styleUrls: ['./map-list.component.scss'],
    providers: [MapService]
})
export class MapListComponent implements OnInit {
  constructor(private _ms: MapService) {
  }

  ngOnInit() {
}
}
