import { Component, OnInit } from '@angular/core';
import { Http } from '@angular/http';
import { AppConfig } from '../../../conf/app.config';
import { GeoJSON } from 'leaflet';
import { MapListService } from '../../../core/GN2Common/map-list/map-list.service';

@Component({
  selector: 'pnx-contact-map-list',
  templateUrl: 'contact-map-list.component.html'
})

export class ContactMapListComponent implements OnInit {
  public data: GeoJSON;

  constructor( private _http: Http, private _mapListService: MapListService) { }

  ngOnInit() {
  this._http.get(`${AppConfig.API_ENDPOINT}contact/releves`)
    .map(res => res.json())
    .subscribe(res =>  { this.data = res; } );
   }


}
