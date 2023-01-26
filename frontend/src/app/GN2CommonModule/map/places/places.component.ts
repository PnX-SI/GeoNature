import { Component, OnInit, ViewChild, OnDestroy } from '@angular/core';
import { FormControl } from '@angular/forms';
import { MarkerComponent } from '../marker/marker.component';
import { MapService } from '../map.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { CommonService } from '../../service/common.service';
import * as L from 'leaflet';
import { Subscription } from 'rxjs/Subscription';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { ConfigService } from '@geonature/services/config.service';

/**
 * Affiche une modale permettant de renseigner le nom d'un lieu et de l'enregistrer dans la table T_PLACE.
 *
 * Ce composant hérite du composant MarkerComponent: il dispose donc des mêmes inputs et outputs.
 */
@Component({
  selector: 'pnx-places',
  templateUrl: 'places.component.html',
})
export class PlacesComponent extends MarkerComponent implements OnInit, OnDestroy {
  @ViewChild('modalContent', { static: false }) public modalContent: any;
  public placeForm = new FormControl();
  private geojsonSubscription$: Subscription;
  public geojson: GeoJSON.Feature;
  constructor(
    public mapService: MapService,
    public modalService: NgbModal,
    public commonService: CommonService,
    private _dfs: DataFormService,
    public config: ConfigService
  ) {
    super(mapService, commonService, config);
  }

  ngOnInit() {
    this.map = this.mapservice.map;
    this.setPlacesLegend();

    this.geojsonSubscription$ = this.mapservice.gettingGeojson$.subscribe((geojson) => {
      this.geojson = geojson;
    });
  }

  setPlacesLegend() {
    // Marker
    const PlacesLegend = this.mapservice.addCustomLegend(
      'topleft',
      'PlacesLegend',
      'url(assets/images/location-save.png)'
    );
    this.map.addControl(new PlacesLegend());
    document.getElementById('PlacesLegend').title = 'Enregistrer un lieu';
    L.DomEvent.disableClickPropagation(document.getElementById('PlacesLegend'));
    document.getElementById('PlacesLegend').onclick = () => {
      if (this.geojson == null) {
        this.commonService.translateToaster(
          'warning',
          "Veuillez d'abord saisir une géométrie sur la carte."
        );
      } else {
        this.modalService.open(this.modalContent);
      }
    };
  }

  addPlace(placeName: String) {
    if (!this.geojson.properties) {
      this.geojson.properties = {};
    }
    this.geojson.properties['place_name'] = placeName.toString();
    this._dfs.addPlace(this.geojson).subscribe((res) => {
      this.commonService.translateToaster('success', 'Lieux ajouté avec succès.');
      this.modalService.dismissAll();
      this.placeForm.reset();
    });
  }

  ngOnDestroy() {
    this.geojsonSubscription$.unsubscribe();
  }
}
