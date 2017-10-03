import { Component, OnInit, OnDestroy } from '@angular/core';
import { Http } from '@angular/http';
import { AppConfig } from '../../../conf/app.config';
import { GeoJSON } from 'leaflet';
import { MapListService } from '../../../core/GN2Common/map-list/map-list.service';
import { Subscription } from 'rxjs/Subscription';

@Component({
  selector: 'pnx-contact-map-list',
  templateUrl: 'contact-map-list.component.html'
})

export class ContactMapListComponent implements OnInit {
  public geojsonData: GeoJSON;
  private idSubscription: Subscription;
  public tableData= new Array();
  public displayColumns: Array<any>;
  public pathEdit: string;
  public pathInfo: string;
  constructor( private _http: Http, private _mapListService: MapListService) { }

  ngOnInit() {
  this.displayColumns = [
   {prop: 'taxons', name: 'Taxon'},
   {prop: 'observateurs', 'name': 'Observateurs'}
  ];
  this.pathEdit = 'contact-form';
  this.pathInfo = 'contact/info';

  this._mapListService.getData('contact/vreleve')
  .subscribe(res => {
    this._mapListService.page.totalElements = res.total;
    this.geojsonData = res.items;
    res.items.features.forEach(feature => {
      const obj = feature.properties;
      obj['id'] = feature.id;
      this.tableData.push(obj);
    });
  });

   }


}


