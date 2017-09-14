import { Component, OnInit } from '@angular/core';
import { NavService } from '../../core/services/nav.service';
import { MapService } from '../../core/GN2Common/map/map.service';
import { AppConfig } from '../../conf/app.config';
import { leafletDrawOption } from '../../core/GN2Common/map/leaflet-draw.options';



@Component({
  selector: 'pnx-contact',
  templateUrl: './contact.component.html',
  styleUrls: ['./contact.component.scss'],
  providers: [MapService]
})
export class ContactComponent implements OnInit {
  public leafletDrawOptions: any;
  constructor(private _navService: NavService, private _ms: MapService) {
      _navService.setAppName('Contact Faune - Flore ');
  }

  ngOnInit() {
    // overight the leaflet draw object to set options
    // examples: enable circle =>  leafletDrawOption.draw.circle = true;
    this.leafletDrawOptions = leafletDrawOption;

   }

  sendGeoIngo(geojson) {
    this._ms.setGeojsonCoord(geojson);
  }

}
