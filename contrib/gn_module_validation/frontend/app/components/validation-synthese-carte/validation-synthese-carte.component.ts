import { Component, OnInit, Input } from '@angular/core';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { leafletDrawOption } from '@geonature_common/map/leaflet-draw.options';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-validation-synthese-carte',
  templateUrl: 'validation-synthese-carte.component.html',
  styleUrls: ['validation-synthese-carte.component.scss'],
  providers: [],
})
export class ValidationSyntheseCarteComponent implements OnInit {
  public leafletDrawOptions = leafletDrawOption;
  @Input() inputSyntheseData: any;

  constructor(
    public mapListService: MapListService,
    public formService: SyntheseFormService,
    public config: ConfigService
  ) {}

  ngOnInit() {
    leafletDrawOption.draw.circle = true;
    leafletDrawOption.draw.rectangle = true;
  }

  onEachFeature(feature, layer) {
    this.mapListService.layerDict[feature.id] = layer;
    layer.on({
      click: () => {
        for (let obs in this.mapListService.layerDict) {
          this.mapListService.layerDict[obs].setStyle(
            this.config.VALIDATION.MAP_POINT_STYLE.originStyle
          );
        }
        // toggle style
        this.mapListService.layerDict[feature.id].setStyle(
          this.config.VALIDATION.MAP_POINT_STYLE.selectedStyle
        );
        // observable
        this.mapListService.mapSelected.next(feature.id);
      },
    });
  }

  bindGeojsonForm(geojson) {
    this.formService.searchForm.controls.geoIntersection.setValue(geojson);
    // set the current coord of the geojson to remove layer from filelayer component via the input removeLayer
    //this.currentLeafletDrawCoord = geojson;
  }

  deleteControlValue() {
    this.formService.searchForm.controls.geoIntersection.reset();
  }
}
