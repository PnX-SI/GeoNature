import { Component, OnInit, ViewChild } from '@angular/core';
import { MarkerComponent } from '../marker/marker.component';
import { MapService } from '../map.service';
import { MapListService } from '../../map-list/map-list.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { CommonService } from '../../service/common.service';
import * as L from 'leaflet';
import { Subscription } from "rxjs/Subscription";
import { Map, GeoJSON, Layer, FeatureGroup, Marker, LatLng } from 'leaflet';

/**
 * Affiche une modale permettant de renseigner les coordonnées d'une observation, puis affiche un marker à la position renseignée.
 *
 * Ce composant hérite du composant MarkerComponent: il dispose donc des mêmes inputs et outputs.
 */
@Component({
  selector: 'pnx-lieux',
  templateUrl: 'lieux.component.html'
})
export class LieuxComponent extends MarkerComponent implements OnInit {
  @ViewChild('modalContent') public modalContent: any;
  private geojsonSubscription$: Subscription;
  public geojson: GeoJSON.Feature;
  constructor(
    public mapService: MapService,
    public modalService: NgbModal,
    public commonService: CommonService,
    private _mapListServive: MapListService,
   
    
  ) {
    super(mapService, commonService);
  }

  ngOnInit() {
    this.map = this.mapservice.map;
    this.setLieuxLegend();
    //this.enableLieux();
    
    this.geojsonSubscription$ = this.mapservice.gettingGeojson$.subscribe(geojson => {
      this.geojson = geojson;
    });
  }

 /* setLieuxLegend() {
    // Marker
    const LieuxLegend = this.mapservice.addCustomLegend(
      'topleft',
      'LieuxLegend',
      'url(assets/images/location-pointer.png)'
    );
    this.map.addControl(new LieuxLegend());
    // custom the marker
    //document.getElementById('LieuxLegend').style.backgroundColor = '#c8c8cc';
    //document.getElementById('LieuxLegend').innerHTML = '<span><b>Lieux<b></span>';
    //document.getElementById('LieuxLegend').style.paddingLeft = '3px';
    L.DomEvent.disableClickPropagation(document.getElementById('LieuxLegend'));
    document.getElementById('LieuxLegend').onclick = () => {
      console.log(this.geojson);
      this.modalService.open(this.modalContent);
    };
  }*/
  
//marine
  setLieuxLegend() {
    // Marker
    const LieuxLegend = this.mapservice.addCustomLegend(
      'topleft',
      'LieuxLegend',
      'url(assets/images/location-pointer.png)'
    );
    this.map.addControl(new LieuxLegend());
    
    L.DomEvent.disableClickPropagation(document.getElementById('LieuxLegend'));
    document.getElementById('LieuxLegend').onclick = () => {
      
      if(this.geojson == null){
        this.commonService.translateToaster('warning', 'Veuillez d\'abord saisir une géométrie sur la carte.');
      }else{
        var geom;
        geom = this.geojson;
        //console.log(this.geojson);
        this.modalService.open(this.modalContent);
      }
    };
  }


  addLieu(nom_lieu:String) {
        
    this.geojson.id=nom_lieu.toString();
    //console.log(this.geojson);
    var geom;
    geom = this.geojson;
    this.mapService.addLieu(geom).subscribe();
    this.modalService.dismissAll();
  }
  









}
