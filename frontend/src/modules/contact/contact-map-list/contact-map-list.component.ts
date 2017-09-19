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
  public releves= new Array();
  constructor( private _http: Http, private _mapListService: MapListService) { }

  ngOnInit() {
  this._http.get(`${AppConfig.API_ENDPOINT}contact/releves`)
    .map(res => res.json())
    .subscribe(res => {
      
       this.geojsonData = res;
       // format data for the table
       res.features.forEach(el => {
        const row: RowsData = {
          id: el.id,
          taxon: el.properties.occurrences.map(occ => occ.nom_cite).join(', '),
          observer: el.properties.observers.map(obs => obs.prenom_role + ' ' + obs.nom_role).join(', '),
          date: el.properties.meta_create_date.substring(0, 10) // get date and cut time of datetime
        };

        this.releves.push(row);
                
      });
            
      } );



  this.idSubscription = this._mapListService.gettingTableId$
    .subscribe(id => {

      const selectedLayer = this._mapListService.layerDict[id];
      const feature = selectedLayer.feature;
      // popup
      const taxonsList = feature.properties.occurrences.map(occ => occ.nom_cite).join(', ');
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
