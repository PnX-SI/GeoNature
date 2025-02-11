import {
  Component,
  OnInit,
  Input,
  AfterViewInit,
  OnChanges,
  EventEmitter,
  Output,
  OnDestroy,
} from '@angular/core';

import { GeoJSON } from 'leaflet';
import * as L from 'leaflet';

import { MapListService } from '@geonature_common/map-list/map-list.service';
import { MapService } from '@geonature_common/map/map.service';
import { leafletDrawOption } from '@geonature_common/map/leaflet-draw.options';
import { CommonService } from '@geonature_common/service/common.service';
import { ConfigService } from '@geonature/services/config.service';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';

import { EventDisplayCriteria, SyntheseCriteriaService } from '@geonature/syntheseModule/services/criteria.service';

@Component({
  selector: 'pnx-synthese-carte',
  templateUrl: 'synthese-carte.component.html',
  styleUrls: ['synthese-carte.component.scss'],
  providers: [],
})
export class SyntheseCarteComponent implements OnInit, AfterViewInit, OnChanges, OnDestroy {
  public leafletDrawOptions = leafletDrawOption;
  public currentLeafletDrawCoord: any;
  public firstFileLayerMessage = true;
  public SYNTHESE_CONFIG = null;
  public clusterOrSimpleFeatureGroup = null;

  public criteriaActivatedSubscription;
  private mapLegend;
  private enableFitBounds = true;

  public selectedLayers: Array<L.Layer> = [];
  public layersDict: object = {};

  private defaultIcon = new L.Icon({
    iconUrl: 'assets/images/default_marker.png',
    iconSize: [28, 38],
    shadowUrl: 'assets/images/marker-shadow.png',
    shadowAnchor: [8, 15],
    shadowSize: [25, 18],
    iconAnchor: [14, 38],
  });

  private selectedIcon = new L.Icon({
    iconUrl: 'assets/images/selected_marker.png',
    iconSize: [28, 38],
    shadowUrl: 'assets/images/marker-shadow.png',
    shadowAnchor: [8, 15],
    shadowSize: [25, 18],
    iconAnchor: [14, 38],
  });

  @Input() inputSyntheseData: GeoJSON;
  @Output() onAreasToggle = new EventEmitter<EventDisplayCriteria>();

  constructor(
    public mapListService: MapListService,
    private _ms: MapService,
    public formService: SyntheseFormService,
    private _commonService: CommonService,
    public config: ConfigService,
    private criteriaService: SyntheseCriteriaService
  ) {
    this.SYNTHESE_CONFIG = this.config.SYNTHESE;
    // set a new featureGroup - cluster or not depending of the synthese config
    this.clusterOrSimpleFeatureGroup = this.config.SYNTHESE.ENABLE_LEAFLET_CLUSTER
      ? (L as any).markerClusterGroup()
      : new L.FeatureGroup();
  }

  ngOnInit() {
    this.leafletDrawOptions.draw.rectangle = true;
    this.leafletDrawOptions.draw.circle = true;
    this.leafletDrawOptions.draw.polyline = false;
    this.leafletDrawOptions.edit.remove = true;
  }

  ngAfterViewInit() {
    // event from the list
    // On table click, change style layer and zoom
    this.mapListService.onTableClick$.subscribe((id) => {
      const selectedLayers = this.layersDict[id];
      if (selectedLayers) {
        this.toggleStyleFromList(selectedLayers);
        const tempFeatureGroup = new L.FeatureGroup();
        selectedLayers.forEach((layer) => {
          tempFeatureGroup.addLayer(layer);
        });
        this._ms.map.fitBounds(tempFeatureGroup.getBounds(), { maxZoom: 18 });
      } else {
        this._commonService.regularToaster(
          'warning',
          "L'observation selectionnée n'est présente dans aucune maille - passez en mode 'point' pour la localiser"
        );
      }
    });

    // Add the featureGroup to the map
    this.clusterOrSimpleFeatureGroup.addTo(this._ms.map);

    // Handle areas button, criteria list and legend
    this.addCriteriaSelectionControl();
    this.addCriteriaMapLegend();
    this.subscribeToCriteriaActivated();
  }

  ngOnDestroy(): void {
    this.criteriaActivatedSubscription.unsubscribe();
  }

  private addCriteriaSelectionControl() {
    const onAddFunc = this.criteriaService.buildSelectionControl();

    if (onAddFunc) {
      const SelectionControl = L.Control.extend({
        options: {
          position: 'topright',
        },
        onAdd: onAddFunc,
      });

      const map = this._ms.getMap();
      map.addControl(new SelectionControl());
    }
  }

  private addCriteriaMapLegend() {
    this.removeCriteriaMapLegend()
    const onAddFunc = this.criteriaService.buildLegendControl();

    if (onAddFunc) {
      const LegendControl = L.Control.extend({
        options: {
          position: 'bottomright',
        },
        onAdd: onAddFunc,
      });

      const map = this._ms.getMap();
      this.mapLegend = new LegendControl();
      this.mapLegend.addTo(map);
    }
  }

  private removeCriteriaMapLegend() {
    if (this.mapLegend) {
      this.mapLegend.remove();
    }
  }

  private subscribeToCriteriaActivated() {
    this.criteriaActivatedSubscription = this.criteriaService.onCriteriaActivated.subscribe(
      (displayCriteriaEvent) => {
        this.onAreasToggle.emit(displayCriteriaEvent);
        this.addCriteriaMapLegend();
      }
    );
  }

  ngOnChanges(change) {
    // Clear layerDict cache
    this.layersDict = {};

    // On change delete the previous layer and load the new ones from the geojson data send by the API.
    // Here we don't use geojson component for performance reasons.
    if (this._ms.map) {
      // Remove the whole featureGroup to avoid iterate over all its layer
      this._ms.map.removeLayer(this.clusterOrSimpleFeatureGroup);
    }

    if (change && change.inputSyntheseData.currentValue) {
      // Regenerate the featuregroup
      this.clusterOrSimpleFeatureGroup = this.config.SYNTHESE.ENABLE_LEAFLET_CLUSTER
        ? (L as any).markerClusterGroup({
            iconCreateFunction: this.overrideClusterCount,
          })
        : new L.FeatureGroup();

      const geojsonLayer = new L.GeoJSON(change.inputSyntheseData.currentValue, {
        pointToLayer: (feature, latlng) => {
          const circleMarker = L.circleMarker(latlng);
          let countObs = feature.properties.observations.id_synthese.length;
          (circleMarker as any).nb_obs = countObs;
          circleMarker.bindTooltip(`${countObs}`, {
            permanent: true,
            direction: 'center',
            offset: L.point({ x: 0, y: 0 }),
            className: 'number-obs',
          });

          return circleMarker;
        },
        style: this.styleFeature.bind(this),
        onEachFeature: this.onEachFeature.bind(this),
      });
      this.clusterOrSimpleFeatureGroup.addLayer(geojsonLayer);
      this._ms.map.addLayer(this.clusterOrSimpleFeatureGroup);

      // Zoom on extend after first search
      if (change.inputSyntheseData.previousValue !== undefined) {
        try {
          // Try to fit bound on layer. catch error if no layer in feature group
          if (this.enableFitBounds) {
            this._ms.map.fitBounds(this.clusterOrSimpleFeatureGroup.getBounds());
          } else {
            this.enableFitBounds = true;
          }
        } catch (error) {}
      }
    }
  }

  overrideClusterCount(cluster) {
    const obsChildCount = cluster
      .getAllChildMarkers()
      .map((layer) => {
        return layer.nb_obs;
      })
      .reduce((previous, next) => previous + next);
    const clusterSize = obsChildCount > 100 ? 'large' : obsChildCount > 10 ? 'medium' : 'small';
    return L.divIcon({
      html: `<div><span>${obsChildCount}</span></div>`,
      className: `marker-cluster marker-cluster-${clusterSize}`,
      iconSize: L.point(40, 40),
    });
  }

  onEachFeature(feature, layer) {
    // make a cache a layers in a dict with id key
    // TODO: change name, it's a observations cache used by synthese list and map !
    this.layerDictCache(feature.properties.observations, layer);

    this.layerEvent(layer, feature.properties.observations);
  }

  layerDictCache(observations, layer) {
    for (let id of observations.id_synthese) {
      id in this.layersDict ? this.layersDict[id].push(layer) : (this.layersDict[id] = [layer]);
    }
  }

  layerEvent(layer, observations) {
    layer.on({
      click: (e) => {
        this.toggleStyleFromMap(observations, layer);
        const idSyntheseIds = observations.id_synthese;
        this.mapListService.mapSelected.next(idSyntheseIds);
        if (this.criteriaService.isAreasAggDisplay()) {
          this.bindAreasPopup(layer, idSyntheseIds);
        }
      },
    });
  }

  private styleFeature(feature) {
    // set style
    if (this.criteriaService.isAreasAggDisplay()) {
      return {
        ...this.criteriaService.originAreasStyle,
        ...{
          fillColor: this.criteriaService.getColor(
            feature.properties.observations.id_synthese.length
          ),
        },
      };
    } else if (this.criteriaService.isDefaultDisplay() === false) {
      return this.criteriaService.getCriteriaStyle(feature.properties.observations);
    }
  }

  private toggleStyleFromMap(observations, layer) {
    // Restore initial style
    if (this.selectedLayers.length > 0) {
      this.selectedLayers.forEach((layer) => {
        (layer as L.GeoJSON).setStyle(this.criteriaService.getOriginStyle(layer));
      });
    }

    // Set selected style
    layer.setStyle(this.criteriaService.getSelectedStyle());
    this.selectedLayers = [layer];
  }

  private toggleStyleFromList(currentSelectedLayers) {
    // Restore inital style
    if (this.selectedLayers.length > 0) {
      this.selectedLayers.forEach((layer) => {
        (layer as L.GeoJSON).setStyle(this.criteriaService.getOriginStyle(layer));
      });
    }

    // Apply new selected layer
    this.selectedLayers = currentSelectedLayers;

    this.selectedLayers.forEach((layer) => {
      (layer as L.GeoJSON).setStyle(this.criteriaService.getSelectedStyle());
    });
  }

  private bindAreasPopup(layer, ids) {
    let popupContent = `<b>${ids.length} observation(s)</b>`;
    layer.bindPopup(popupContent).openPopup();
  }

  bindGeojsonForm(geojson) {
    this.formService.searchForm.controls.geoIntersection.setValue(geojson);
    // set the current coord of the geojson to remove layer from filelayer component via the input removeLayer
    this.currentLeafletDrawCoord = geojson;
  }

  onFileLayerLoaded(geojson) {
    this.formService.searchForm.controls.geoIntersection.setValue(geojson);

    if (this.firstFileLayerMessage) {
      this._commonService.translateToaster('success', 'Map.Messages.FileLayerInfoSynthese');
    }
    this.firstFileLayerMessage = false;
  }

  deleteControlValue() {
    this.formService.searchForm.controls.geoIntersection.reset();
  }
}
