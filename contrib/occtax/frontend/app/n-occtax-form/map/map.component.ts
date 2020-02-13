import { Component, OnInit } from "@angular/core";
import { leafletDrawOption } from "@geonature_common/map/leaflet-draw.options";
import { CommonService } from "@geonature_common/service/common.service";
import { GeoJSON } from "leaflet";
import { ModuleConfig } from "../../module.config";
import { OcctaxFormMapService } from './map.service';
import { OcctaxFormService } from '../occtax-form.service';

@Component({
  selector: "pnx-occtax-form-map",
  templateUrl: "map.component.html"
})
export class OcctaxFormMapComponent implements OnInit {
  
  public leafletDrawOptions: any;
  public firstFileLayerMessage = true;
  public occtaxConfig = ModuleConfig;

  constructor(
    private ms: OcctaxFormMapService,
    private _commonService: CommonService,
    public fs: OcctaxFormService,
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
  }

  // display help toaster for filelayer
  infoMessageFileLayer() {
    if (this.firstFileLayerMessage) {
      this._commonService.translateToaster("info", "Map.FileLayerInfoMessage");
    }
    this.firstFileLayerMessage = false;
  }

  sendGeoInfo(geojson) {
    this.ms.geojson.next(geojson);
  }

  get coordinates(): Array<number> {
    if ()
    return null;
  }

  get geojson(): GeoJSON {
    console.log(this.ms.geojson.getValue())
    return this.ms.geojson.getValue();
  }
}
