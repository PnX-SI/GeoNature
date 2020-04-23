import { Component, OnInit, OnDestroy } from "@angular/core";
import { filter, map } from 'rxjs/operators';
import { leafletDrawOption } from "@geonature_common/map/leaflet-draw.options";
import { CommonService } from "@geonature_common/service/common.service";
import { GeoJSON } from "leaflet";
import { ModuleConfig } from "../../module.config";
import { OcctaxFormMapService } from './map.service';

@Component({
  selector: "pnx-occtax-form-map",
  templateUrl: "map.component.html"
})
export class OcctaxFormMapComponent implements OnInit, OnDestroy {
  
  public leafletDrawOptions: any;
  public firstFileLayerMessage = true;
  public occtaxConfig = ModuleConfig;

  public coordinates = null;
  public geometry = null;

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

    this.ms.geojson
                .pipe(
                  filter(geojson=>geojson !== null),
                  map(geojson=>geojson.geometry)
                )
                .subscribe(geometry => {
                  if (geometry.type == "Point") {
                    // set the input for the marker component
                    this.coordinates = geometry.coordinates;
                  } else {
                    // set the input for leafletdraw component
                    this.geometry = geometry;
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

  ngOnDestroy() {
    this.ms.reset();
  }
}
