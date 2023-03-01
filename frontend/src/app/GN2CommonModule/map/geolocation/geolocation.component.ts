import { Component, OnInit, OnChanges, ViewChild, ElementRef } from '@angular/core';
import { Map } from 'leaflet';

import { MapService } from '../map.service';
import { AppConfig } from '@geonature_config/app.config';
import { CommonService } from '../../service/common.service';

import * as L from 'leaflet';

@Component({
  selector: 'pnx-geolocation-button',
  templateUrl: 'geolocation.component.html'
})
export class GeolocationComponent {
  @ViewChild('map') public mapElement: ElementRef;
  map: L.Map;

  constructor(public mapservice: MapService, private _commonService: CommonService) {}



  ngOnInit() {
    this.map = this.mapservice.map;
    this.setMarkerGeolocation();
  }

  setMarkerGeolocation()  {
    // Marker
    const MarkerGeolocation = this.mapservice.addCustomLegend(
      'topleft',
      'markerGeolocation',
      'url(assets/images/icons8-where-34.png)'
    );
    this.map.addControl(new MarkerGeolocation());
    // custom the marker
    // document.getElementById('markerGeolocation').style.backgroundColor = '#edcb44';
    document.getElementById('markerGeolocation').style.backgroundPosition = ' 0px center';
  
    L.DomEvent.disableClickPropagation(document.getElementById('markerGeolocation'));
    document.getElementById('markerGeolocation').onclick = () => {
      this.getCurrentLocation();
    };
  }


  getCurrentLocation() {

    // bug : non affichage du marker si usage de 'url(assets/images/icons8-where-34.png)'
    // je pense, relié a https://github.com/PnX-SI/GeoNature/tree/feat/leaflet-marker
    var mobileIcon = L.icon({
      iconUrl: 'https://geonature.bretagne-vivante-dev.org/assets/images/icons8-street-view-50.png',
      iconSize:     [50, 50] // size of the icon
    })
  
    // amélioration possible a faire  
    var DesktopIcon = L.icon({
      iconUrl: 'https://geonature.bretagne-vivante-dev.org/assets/images/icons8-street-view-50.png',
      iconSize:     [50, 50] // size of the icon
    })

    // ajouter if pour le type de device et modifier l'icone marker en fonction
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(position => {
        const latitude = position.coords.latitude;
        const longitude = position.coords.longitude;
        console.log(`Latitude : ${latitude}, Longitude : ${longitude}`);
        this.map.setView([latitude, longitude], 18); // zoom max sur la localisation
        L.marker([latitude, longitude], {icon: mobileIcon}).addTo(this.map); // ajout d'un marker
      });
    } else {
      console.error("La géolocalisation n'est pas prise en charge par votre navigateur.");
    }
  }

  ngAfterViewInit() {
    this.map = L.map(this.mapElement.nativeElement).setView([47.21837, -1.55362], 13); // initialisation de la carte
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: 'OpenStreetMap'
    }).addTo(this.map);
  }
}
