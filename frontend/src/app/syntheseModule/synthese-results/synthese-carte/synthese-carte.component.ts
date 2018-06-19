import { Component, OnInit, Input, AfterViewInit } from '@angular/core';
import { GeoJSON } from 'leaflet';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { MapService } from '@geonature_common/map/map.service';
import { leafletDrawOption } from '@geonature_common/map/leaflet-draw.options';
import { FormService } from '../../services/form.service';

@Component({
  selector: 'pnx-synthese-carte',
  templateUrl: 'synthese-carte.component.html',
  styleUrls: ['synthese-carte.component.scss'],
  providers: [MapService]
})
export class SyntheseCarteComponent implements OnInit, AfterViewInit {
  public leafletDrawOptions = leafletDrawOption;
  @Input() inputSyntheseData: GeoJSON;
  constructor(
    public mapListService: MapListService,
    private _ms: MapService,
    public formService: FormService
  ) {}

  ngOnInit() {
    this.leafletDrawOptions.draw.rectangle = true;
    this.leafletDrawOptions.draw.circle = true;
    this.leafletDrawOptions.draw.polyline = false;
  }

  ngAfterViewInit() {
    // event from the list
    this.mapListService.enableMapListConnexion(this._ms.getMap());
  }

  onEachFeature(feature, layer) {
    // event from the map
    this.mapListService.layerDict[feature.id] = layer;
    layer.on({
      click: e => {
        // toggle style
        this.mapListService.toggleStyle(layer);
        // observable
        this.mapListService.mapSelected.next(feature.id);
        // open popup
        // layer.bindPopup(feature.properties.leaflet_popup).openPopup();
      }
    });
  }

  bindGeojsonForm(geojson) {
    this.formService.searchForm.controls.geoIntersection.setValue(geojson);
  }
}
