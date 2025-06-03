import { Injectable, OnInit } from '@angular/core';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { leafletDrawOption } from '@geonature_common/map/leaflet-draw.options';

@Injectable()
export class SyntheseCarteDrawingService implements OnInit {
  public leafletDrawOptions = leafletDrawOption;
  public currentLeafletDrawCoord: any;

  constructor(private _formService: SyntheseFormService) {}

  ngOnInit() {
    this.leafletDrawOptions.draw.rectangle = true;
    this.leafletDrawOptions.draw.circle = true;
    this.leafletDrawOptions.draw.polyline = false;
    this.leafletDrawOptions.edit.remove = true;
  }

  layerDrawed(geojson) {
    this._formService.searchForm.controls.geoIntersection.setValue(geojson);

    // set the current coord of the geojson to remove layer from filelayer component via the input removeLayer
    this.currentLeafletDrawCoord = geojson;
  }

  layerDeleted() {
    this._formService.searchForm.controls.geoIntersection.reset();
  }
}
