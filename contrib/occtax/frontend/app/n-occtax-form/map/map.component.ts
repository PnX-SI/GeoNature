import { Component, OnInit, AfterViewInit } from "@angular/core";
import { filter } from 'rxjs/operators';
import { leafletDrawOption } from "@geonature_common/map/leaflet-draw.options";
import { CommonService } from "@geonature_common/service/common.service";
import { GeoJSON } from "leaflet";
import { ModuleConfig } from "../../module.config";
import { OcctaxFormMapService } from './map.service';

@Component({
  selector: "pnx-occtax-form-map",
  templateUrl: "map.component.html"
})
export class OcctaxFormMapComponent implements OnInit, AfterViewInit {
  
  public leafletDrawOptions: any;
  public firstFileLayerMessage = true;
  public occtaxConfig = ModuleConfig;

  public coordinates = null;
  public geojson = null;

  constructor(
    private ms: OcctaxFormMapService,
    private _commonService: CommonService
  ) {}

  ngOnInit() {
    // overight the leaflet draw object to set options
    // examples: enable circle =>  leafletDrawOption.draw.circle = true;
    leafletDrawOption.draw.circle = false;
    leafletDrawOption.draw.rectangle = false;
    leafletDrawOption.draw.marker = false;
    leafletDrawOption.draw.polyline = true;
    leafletDrawOption.edit.remove = false;
    this.leafletDrawOptions = leafletDrawOption;

    this.ms.geometry
                .valueChanges
                .subscribe(geojson => {
                  if (geojson.type == "Point") {
                    // set the input for the marker component
                    this.coordinates = geojson.coordinates;
                  } else {
                    // set the input for leafletdraw component
                    this.geojson = geojson;
                  }
                });

  }

  // display help toaster for filelayer
  infoMessageFileLayer() {
    if (this.firstFileLayerMessage) {
      this._commonService.translateToaster("info", "Map.FileLayerInfoMessage");
    }
    this.firstFileLayerMessage = false;
  }

  sendGeoInfo(geojson) {
    this.ms.geometry = geojson;
  }
}
