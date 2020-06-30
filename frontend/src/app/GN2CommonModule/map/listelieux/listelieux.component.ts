import { Component, OnInit, ViewChild, OnDestroy } from '@angular/core';
import { MarkerComponent } from '../marker/marker.component';
import { MapService } from '../map.service';
import { MapListService } from '../../map-list/map-list.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { CommonService } from '../../service/common.service';
import * as L from 'leaflet';
import { Subscription } from "rxjs/Subscription";
import { Observable, throwError } from 'rxjs';
import { Map, GeoJSON, Layer, FeatureGroup, Marker, LatLng } from 'leaflet';




/**
 * Affiche une modale permettant de renseigner les coordonnées d'une observation, puis affiche un marker à la position renseignée.
 *
 * Ce composant hérite du composant MarkerComponent: il dispose donc des mêmes inputs et outputs.
 */
@Component({
  selector: 'pnx-listelieux',
  templateUrl: 'listelieux.component.html'
})
export class ListeLieuxComponent extends MarkerComponent implements OnInit, OnDestroy {
  @ViewChild('modalContent') public modalContent: any;
  private geojsonSubscription$: Subscription;
  public geojson: any;
  public lieux:any[];
  public listLieuSub: Subscription;
  public selectedLieu: GeoJSON.Feature ;
  public delLieuSub: Subscription;
  public delLieuxRes:string;
  
  

  constructor(
    public mapService: MapService,
    public modalService: NgbModal,
    public commonService: CommonService,
    private _mapListServive: MapListService
    
  ) {
    super(mapService, commonService);
  }

  ngOnInit() {
    this.map = this.mapservice.map;
    this.setLieuxLegend();
    
  }

  

  setLieuxLegend() {
    // Marker
    const LieuxLegend = this.mapservice.addCustomLegend(
      'topleft',
      'ListeLieuxLegend',
      'url(assets/images/liste.png)'
    );
    this.map.addControl(new LieuxLegend());
    L.DomEvent.disableClickPropagation(document.getElementById('ListeLieuxLegend'));
    document.getElementById('ListeLieuxLegend').onclick = () => {

     this.listLieuSub = this.mapService.
      getLieux()
      .subscribe(res => {
          this.lieux = res;
        },
        console.error
      );

    
      this.modalService.open(this.modalContent);
      
    };
  }

 
  onSelectLieu(lieu:GeoJSON.Feature){
    //alert(lieu.id.toString());
    this.selectedLieu=lieu;
    this.mapService.afficheLieux(lieu);
    
   
  }

  deleteLieu(){
    //alert(this.selectedLieu.id);
    this.mapService.deleteLieu(this.selectedLieu.id.toString()).subscribe();
    this.modalService.dismissAll();
    this.listLieuSub = this.mapService.
    getLieux()
    .subscribe(res => {
        this.lieux = res;
      },
      console.error
    );
    this.modalService.open(this.modalContent);
    alert(this.selectedLieu.id.toString()+" est supprimé");
   }



   

  ngOnDestroy() {
    //alert("ok");
    //this.mapService.removeAllLayers(this.map, this.selectedLieu)
  }
  
  

}
