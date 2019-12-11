import { Component, OnInit, Output, EventEmitter } from "@angular/core";
import { MapService } from "@geonature_common/map/map.service";
import * as L from "leaflet";

@Component({
  selector: "pnx-occhab-dataset-map-overlay",
  template: ""
})
export class OccHabDatasetMapOverlayComponent implements OnInit {
  @Output() getBoundingBox = new EventEmitter();
  constructor(private _mapService: MapService) {}

  ngOnInit() {
    const CustomLegend = this._mapService.addCustomLegend(
      "topright",
      "occHabLayerControl",
      "url(assets/images/location-pointer.png)"
    );
    this._mapService.map.addControl(new CustomLegend());
    // L.DomEvent.disableClickPropagation(
    //   document.getElementById("occHabLayerControl")
    // );

    document.getElementById("occHabLayerControl").onclick = () => {
      const bounds = this._mapService.map.getBounds();
      this.getBoundingBox.emit({
        southEast: bounds.getSouthEast(),
        southWest: bounds.getSouthWest(),
        northEast: bounds.getNorthEast(),
        northWest: bounds.getNorthWest()
      });
    };
  }
}
