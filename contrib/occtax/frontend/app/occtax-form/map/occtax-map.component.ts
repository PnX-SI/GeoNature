import { Component, OnInit, AfterViewInit, OnDestroy } from "@angular/core";
import { leafletDrawOption } from "@geonature_common/map/leaflet-draw.options";
import { CommonService } from "@geonature_common/service/common.service";
import { MapService } from "@geonature_common/map/map.service";
import { OcctaxFormMapService } from "./occtax-map.service";
import { ConfigService } from "@geonature/services/config.service";
import { OcctaxDataService } from "../../services/occtax-data.service";

@Component({
  selector: "pnx-occtax-form-map",
  templateUrl: "occtax-map.component.html",
})
export class OcctaxFormMapComponent
  implements OnInit, AfterViewInit, OnDestroy
{
  public leafletDrawOptions: any;
  public firstFileLayerMessage = true;

  public coordinates = null;
  public geometry = null;
  public firstGeom = true;
  public moduleConfig;

  constructor(
    public ms: OcctaxFormMapService,
    private _commonService: CommonService,
    private _mapService: MapService,
    public configService: ConfigService,
    public dataService: OcctaxDataService,
  ) {}

  ngOnInit() {
    this.moduleConfig = this.dataService.moduleConfig;

    // overight the leaflet draw object to set options
    // examples: enable circle =>  leafletDrawOption.draw.circle = true;
    leafletDrawOption.draw.circle = false;
    leafletDrawOption.draw.rectangle = false;
    leafletDrawOption.draw.marker = false;
    leafletDrawOption.draw.polyline = true;
    leafletDrawOption.edit.remove = false;
    this.leafletDrawOptions = leafletDrawOption;
  }

  ngAfterViewInit() {
    if (this._mapService.currentExtend) {
      this._mapService.map.setView(
        this._mapService.currentExtend.center,
        this._mapService.currentExtend.zoom,
      );
    }
    let filelayerFeatures = this._mapService.fileLayerFeatureGroup.getLayers();
    // si il y a encore des filelayer -> on désactive le marker par defaut
    if (filelayerFeatures.length > 0) {
      this._mapService.setEditingMarker(false);
      this._mapService.fileLayerEditionMode = true;
    }

    filelayerFeatures.forEach((el) => {
      if ((el as any).getLayers()[0].options.color == "red") {
        (el as any).setStyle({ color: "green", opacity: 0.2 });
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

  ngOnDestroy() {
    this.ms.reset();
  }
}
