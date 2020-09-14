import { Component, OnInit, ViewChild, OnDestroy, EventEmitter, Output } from '@angular/core';
import { MarkerComponent } from '../marker/marker.component';
import { MapService } from '../map.service';
import { MapListService } from '../../map-list/map-list.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { CommonService } from '../../service/common.service';
import * as L from 'leaflet';
import { Subscription } from "rxjs/Subscription";
import { Observable, throwError } from 'rxjs';
import { Map, GeoJSON, Layer, FeatureGroup, Marker, LatLng } from 'leaflet';
import { DataFormService } from '@geonature_common/form/data-form.service';
//import { LieuxComponent } from '../lieux/lieux.component';




/**
 * Affiche une modale permettant d'aficher la liste des lieux enregistrés pour l'utilisateur actif, puis affiche le lieux sélectionnés sur la carte.
 *
 * Ce composant hérite du composant MarkerComponent: il dispose donc des mêmes inputs et outputs.
 */
@Component({
  selector: 'pnx-placesList',
  templateUrl: 'placesList.component.html'
})
export class PlacesListComponent extends MarkerComponent implements OnInit, OnDestroy {
  @ViewChild('modalContent') public modalContent: any;
  private geojsonSubscription$: Subscription;
  public geojson: any;
  public places:any[];
  public listPlacesSub: Subscription;
  public selectedPlace: GeoJSON.Feature ;
  public delPlaceSub: Subscription;
  public delPlaceRes:string;
  public place:GeoJSON.Feature;
  
  @Output() layerDrawed = new EventEmitter<GeoJSON>();

  constructor(
    public mapService: MapService,
    public modalService: NgbModal,
    public commonService: CommonService,
    private _dfs: DataFormService,
    private _mapListServive: MapListService
    
  ) {
    super(mapService, commonService);
  }

  ngOnInit() {
    this.map = this.mapservice.map;
    this.setPlacesLegend();
    
  }

  

  setPlacesLegend() {
    // icon
    const placesLegend = this.mapservice.addCustomLegend(
      'topleft',
      'ListPlacesLegend',
      'url(assets/images/liste.png)'
    );
    this.map.addControl(new placesLegend());
    document.getElementById('ListPlacesLegend').title = "Liste des lieux";
    L.DomEvent.disableClickPropagation(document.getElementById('ListPlacesLegend'));
       document.getElementById('ListPlacesLegend').onclick = () => {

     this.listPlacesSub = this._dfs.
      getPlaces()
      .subscribe(res => {
          this.places = res;
        },
        console.error
      );

    
      this.modalService.open(this.modalContent);
      
    };
  }

  loadPlace(){
    this.selectedPlace=this.place;

    //Bien cleaner tous les types de géométrie possible
    if (this.mapservice.marker !== undefined) {
      this.mapService.map.removeLayer(this.mapService.marker);
    }
    this.mapservice.removeAllLayers(this.map, this.mapService.leafletDrawFeatureGroup);
    this.mapservice.removeAllLayers(this.map, this.mapService.fileLayerFeatureGroup);

    this.mapservice.firstLayerFromMap = false;
    this.layerDrawed.emit(L.geoJSON(this.selectedPlace));
    this.mapService.loadGeometryReleve(this.selectedPlace, true);
  }

  deletePlace(){
    if(confirm("Êtes-vous sûr de vouloir supprimer ce lieu?")) {
        this._dfs.deletePlace(this.selectedPlace.id).subscribe(res => {
          this.commonService.translateToaster('success', 'Un lieu a été supprimé');
          this.listPlacesSub = this._dfs.
          getPlaces()
          .subscribe(res => {
              this.places = res;
            },
            console.error
          );
        }    
      );
    }
   }

  ngOnDestroy() {
    //alert("ok");
    //this.mapService.removeAllLayers(this.map, this.selectedPlace)
  }
  
  

}
