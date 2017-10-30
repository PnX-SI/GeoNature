import { Component, OnInit, OnDestroy } from '@angular/core';
import { NavService } from '../../../core/services/nav.service';
import { MapService } from '../../../core/GN2Common/map/map.service';
import { AppConfig } from '../../../conf/app.config';
import { leafletDrawOption } from '../../../core/GN2Common/map/leaflet-draw.options';
import { ActivatedRoute, Router } from '@angular/router';
import { Subscription } from 'rxjs/Subscription';



@Component({
  selector: 'pnx-contact-map-form',
  templateUrl: './contact-map-form.component.html',
  styleUrls: ['./contact-map-form.component.scss'],
  providers: [MapService]
})
export class ContactMapFormComponent implements OnInit, OnDestroy {
  public leafletDrawOptions: any;
  private _sub: Subscription;
  public id: number;
  constructor(private _navService: NavService, private _ms: MapService, private _route: ActivatedRoute,
  private _router: Router) {
  }

  ngOnInit() {
    // overight the leaflet draw object to set options
    // examples: enable circle =>  leafletDrawOption.draw.circle = true;
    this.leafletDrawOptions = leafletDrawOption;
    // get the id from the route
    this._sub = this._route.params.subscribe(params => {
      this.id = +params['id'];

    });
   }

  sendGeoInfo(geojson) {
    this._ms.setGeojsonCoord(geojson);
  }

  ngOnDestroy() {
    this._sub.unsubscribe();
  }

}
