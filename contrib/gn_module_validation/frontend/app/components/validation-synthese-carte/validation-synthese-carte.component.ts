import { Component, OnInit, Input } from "@angular/core";
//import { GeoJSON } from "leaflet";
import { MapListService } from "@geonature_common/map-list/map-list.service";
import { MapService } from "@geonature_common/map/map.service";
import { leafletDrawOption } from "@geonature_common/map/leaflet-draw.options";
import { ModuleConfig } from "../../module.config";
import { SyntheseFormService } from "@geonature_common/form/synthese-form/synthese-form.service";

@Component({
  selector: "pnx-validation-synthese-carte",
  templateUrl: "validation-synthese-carte.component.html",
  styleUrls: ["validation-synthese-carte.component.scss"],
  providers: []
})
export class ValidationSyntheseCarteComponent implements OnInit {
  public leafletDrawOptions = leafletDrawOption;
  public VALIDATION_CONFIG = ModuleConfig;
  @Input() inputSyntheseData: any;
  constructor(
    public mapListService: MapListService,
    private _ms: MapService,
    public formService: SyntheseFormService
  ) {}

  ngOnInit() {
    leafletDrawOption.draw.circle = true;
    leafletDrawOption.draw.rectangle = true;
  }

  onEachFeature(feature, layer) {
    this.mapListService.layerDict[feature.id] = layer;
    layer.on({
      click: e => {
        for (let obs in this.mapListService.layerDict) {
          this.mapListService.layerDict[obs].setStyle(
            this.VALIDATION_CONFIG.MAP_POINT_STYLE.originStyle
          );
        }
        // toggle style
        this.mapListService.layerDict[feature.id].setStyle(
          this.VALIDATION_CONFIG.MAP_POINT_STYLE.selectedStyle
        );
        // observable
        this.mapListService.mapSelected.next(feature.id);
      }
    });
  }

  bindGeojsonForm(geojson) {
    this.formService.searchForm.controls.radius.setValue(
      geojson.properties["radius"]
    );
    this.formService.searchForm.controls.geoIntersection.setValue(geojson);
    // set the current coord of the geojson to remove layer from filelayer component via the input removeLayer
    //this.currentLeafletDrawCoord = geojson;
  }

  deleteControlValue() {
    this.formService.searchForm.controls.geoIntersection.reset();
    this.formService.searchForm.controls.radius.reset();
  }
}
