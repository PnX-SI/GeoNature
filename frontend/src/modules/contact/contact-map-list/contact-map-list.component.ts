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

export class ContactMapListComponent implements OnInit, OnDestroy {
  public geojsonData: GeoJSON;
  private idSubscription: Subscription;
  public tableData= new Array();
  public columns: Array<any>;
  constructor( private _http: Http, private _mapListService: MapListService) { }

  ngOnInit() {
  this.columns = [
   {prop: 'nom_valide', name: 'Taxon'},
   {prop: 'observateurs', 'name': 'Observateurs'}
  ];


  this.idSubscription = this._mapListService.gettingTableId$
    .subscribe(id => {

      const selectedLayer = this._mapListService.layerDict[id];
      const feature = selectedLayer.feature;
      // popup
      const taxonsList = feature.properties.t_occurrences_contact.map(occ => occ.nom_cite).join(', ');
      const observersList = feature.properties.observers.map(obs =>  obs.prenom_role + ' ' + obs.nom_role).join(', ');
      const popupContent = `<b> Id relevé: </b>: ${feature.id} <br>
                              <b> Observateur(s): </b> ${observersList} <br>
                              <b> Taxon(s): </b> ${taxonsList}`;
      selectedLayer.bindPopup(popupContent).openPopup();

    });
   }

  ngOnDestroy() {
    this.idSubscription.unsubscribe();
  }
}

export interface RowsData {
  id: string;
  taxon: any;
  observer: any;
  date: any;
}
