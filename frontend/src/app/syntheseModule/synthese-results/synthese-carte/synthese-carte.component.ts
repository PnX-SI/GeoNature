import {
  Component,
  OnInit,
  Input,
  AfterViewInit,
  EventEmitter,
  OnChanges,
  Output,
  OnDestroy,
} from '@angular/core';
import { GeoJSON } from 'leaflet';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { MapService } from '@geonature_common/map/map.service';
import { leafletDrawOption } from '@geonature_common/map/leaflet-draw.options';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { CommonService } from '@geonature_common/service/common.service';
import * as L from 'leaflet';
import { LangChangeEvent, TranslateService } from '@ngx-translate/core';
import { takeUntil } from 'rxjs/operators';
import { Subject } from 'rxjs';
import { ConfigService } from '@geonature/services/config.service';

export type EventToggle = 'grid' | 'point';

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
  public cluserOrSimpleFeatureGroup = null;

  private destroy$: Subject<boolean> = new Subject<boolean>();

  private areasEnable;
  private areasLegend;
  private enableFitBounds = true;
  private areasLabelSwitchBtn;
  public selectedLayers: Array<L.Layer> = [];
  public layersDict: object = {};

  private originDefaultStyle = {
    color: '#3388FF',
    weight: 3,
    fill: false,
  };
  private selectedDefaultStyle = {
    color: '#FF0000',
  };
  private originAreasStyle = {
    color: '#FFFFFF',
    weight: 0.4,
    fillOpacity: 0.8,
  };
  private selectedAreasStyle = {
    color: '#FF0000',
    weight: 3,
  };

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
  @Output() onAreasToggle = new EventEmitter<EventToggle>();

  constructor(
    public mapListService: MapListService,
    private _ms: MapService,
    public formService: SyntheseFormService,
    private _commonService: CommonService,
    private translateService: TranslateService,
    public config: ConfigService
  ) {
    this.SYNTHESE_CONFIG = this.config.SYNTHESE;
    // set a new featureGroup - cluster or not depending of the synthese config
    this.cluserOrSimpleFeatureGroup = this.config.SYNTHESE.ENABLE_LEAFLET_CLUSTER
      ? (L as any).markerClusterGroup()
      : new L.FeatureGroup();
    this.areasEnable =
      this.config.SYNTHESE.AREA_AGGREGATION_ENABLED &&
      this.config.SYNTHESE.AREA_AGGREGATION_BY_DEFAULT;
  }

  ngOnInit() {
    this.leafletDrawOptions.draw.rectangle = true;
    this.leafletDrawOptions.draw.circle = true;
    this.leafletDrawOptions.draw.polyline = false;
    this.leafletDrawOptions.edit.remove = true;
    this.initializeFormWithMapParams();
  }

  private initializeFormWithMapParams() {
    this.formService.searchForm.patchValue({
      format: this.areasEnable ? 'grouped_geom_by_areas' : 'grouped_geom',
    });
  }

  ngOnDestroy() {
    this.destroy$.next(true);
    this.destroy$.unsubscribe();
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

    // add the featureGroup to the map
    this.cluserOrSimpleFeatureGroup.addTo(this._ms.map);

    // Handle areas button and legend
    if (this.config.SYNTHESE.AREA_AGGREGATION_ENABLED) {
      this.addAreasButton();
      this.onLanguageChange();
      if (this.areasEnable) {
        this.addAreasLegend();
      }
    }
  }

  private onLanguageChange() {
    // don't forget to unsubscribe!
    this.translateService.onLangChange
      .pipe(takeUntil(this.destroy$))
      .subscribe((langChangeEvent: LangChangeEvent) => {
        this.defineI18nMessages();
      });
  }

  private defineI18nMessages() {
    // Define default messages for datatable
    this.translateService
      .get('Synthese.Map.AreasToggleBtn')
      .subscribe((translatedTxt: string[]) => {
        this.areasLabelSwitchBtn.innerText = translatedTxt;
      });
  }

  addAreasButton() {
    const LayerControl = L.Control.extend({
      options: {
        position: 'topright',
      },
      onAdd: (map) => {
        let switchBtnContainer = L.DomUtil.create(
          'div',
          'leaflet-bar custom-control custom-switch leaflet-control-custom synthese-map-areas'
        );

        let switchBtn = L.DomUtil.create('input', 'custom-control-input', switchBtnContainer);
        switchBtn.id = 'toggle-areas-btn';
        switchBtn.type = 'checkbox';
        switchBtn.checked = this.config.SYNTHESE.AREA_AGGREGATION_BY_DEFAULT;
        switchBtn.onclick = () => {
          this.areasEnable = switchBtn.checked;
          this.formService.selectors = this.formService.selectors.set(
            'format',
            switchBtn.checked ? 'grouped_geom_by_areas' : 'grouped_geom'
          );
          this.onAreasToggle.emit(switchBtn.checked ? 'grid' : 'point');

          // Show areas legend if areas toggle button is enable
          if (this.areasEnable) {
            this.addAreasLegend();
          } else {
            this.removeAreasLegend();
            this.enableFitBounds = false;
          }
        };

        this.areasLabelSwitchBtn = L.DomUtil.create(
          'label',
          'custom-control-label',
          switchBtnContainer
        );
        this.areasLabelSwitchBtn.setAttribute('for', 'toggle-areas-btn');
        this.areasLabelSwitchBtn.innerText = this.translateService.instant(
          'Synthese.Map.AreasToggleBtn'
        );

        return switchBtnContainer;
      },
    });

    const map = this._ms.getMap();
    map.addControl(new LayerControl());
  }

  private addAreasLegend() {
    this.areasLegend = new (L.Control.extend({
      options: { position: 'bottomright' },
    }))();

    const vm = this;
    this.areasLegend.onAdd = (map) => {
      let div = L.DomUtil.create('div', 'info legend');
      let grades = this.config['SYNTHESE']['AREA_AGGREGATION_LEGEND_CLASSES']
        .map((legendClass) => legendClass.min)
        .reverse();
      let labels = ["<strong> Nombre <br> d'observations </strong> <br>"];

      // loop through our density intervals and generate a label with a colored square for each interval
      for (var i = 0; i < grades.length; i++) {
        labels.push(
          '<i style="background:' +
            vm.getColor(grades[i] + 1) +
            '"></i> ' +
            grades[i] +
            (grades[i + 1] ? '&ndash;' + grades[i + 1] + '<br>' : '+')
        );
      }
      div.innerHTML = labels.join('<br>');

      return div;
    };

    const map = this._ms.getMap();
    this.areasLegend.addTo(map);
  }

  private removeAreasLegend() {
    const map = this._ms.getMap();
    this.areasLegend.remove(map);
  }

  layerDictCache(idSyntheseList, layer) {
    for (let id of idSyntheseList) {
      id in this.layersDict ? this.layersDict[id].push(layer) : (this.layersDict[id] = [layer]);
    }
  }

  layerEvent(feature, layer, idSyntheseIds) {
    layer.on({
      click: (e) => {
        this.toggleStyleFromMap(feature, layer);
        this.mapListService.mapSelected.next(idSyntheseIds);
        if (this.areasEnable) {
          this.bindAreasPopup(layer, idSyntheseIds);
        }
      },
    });
  }

  onEachFeature(feature, layer) {
    // make a cache a layers in a dict with id key
    this.layerDictCache(feature.properties.observations.id, layer);
    // set style
    if (this.areasEnable) {
      this.setAreasStyle(layer, feature.properties.observations.id.length);
    }
    this.layerEvent(feature, layer, feature.properties.observations.id);
  }

  /**
   *
   */
  clusterCountOverrideFn(cluster) {
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

  ngOnChanges(change) {
    // clear layerDict cache
    this.layersDict = {};
    // on change delete the previous layer and load the new ones from the geojson data send by the API
    // here we don't use geojson component for performance reasons
    if (this._ms.map) {
      // remove the whole featureGroup to avoid iterate over all its layer
      this._ms.map.removeLayer(this.cluserOrSimpleFeatureGroup);
    }
    if (change && change.inputSyntheseData.currentValue) {
      // regenerate the featuregroup
      this.cluserOrSimpleFeatureGroup = this.config.SYNTHESE.ENABLE_LEAFLET_CLUSTER
        ? (L as any).markerClusterGroup({
            iconCreateFunction: this.clusterCountOverrideFn,
          })
        : new L.FeatureGroup();
      const geojsonLayer = new L.GeoJSON(change.inputSyntheseData.currentValue, {
        pointToLayer: (feature, latlng) => {
          const circleMarker = L.circleMarker(latlng);
          let countObs = feature.properties.observations.id.length;
          (circleMarker as any).nb_obs = countObs;
          circleMarker.bindTooltip(`${countObs}`, {
            permanent: true,
            direction: 'center',
            offset: L.point({ x: 0, y: 0 }),
            className: 'number-obs',
          });

          return circleMarker;
        },
        onEachFeature: this.onEachFeature.bind(this),
      });
      this.cluserOrSimpleFeatureGroup.addLayer(geojsonLayer);
      this._ms.map.addLayer(this.cluserOrSimpleFeatureGroup);
      // zoom on extend after first search
      if (change.inputSyntheseData.previousValue !== undefined) {
        try {
          // try to fit bound on layer. catch error if no layer in feature group
          if (this.enableFitBounds) {
            this._ms.map.fitBounds(this.cluserOrSimpleFeatureGroup.getBounds());
          } else {
            this.enableFitBounds = true;
          }
        } catch (error) {}
      }
    }
  }

  private setAreasStyle(layer, obsNbr) {
    this.originAreasStyle['fillColor'] = this.getColor(obsNbr);
    layer.setStyle(this.originAreasStyle);
    delete this.originAreasStyle['fillColor'];
  }

  private getColor(obsNbr) {
    let classesNbr = this.config['SYNTHESE']['AREA_AGGREGATION_LEGEND_CLASSES'].length;
    let lastIndex = classesNbr - 1;
    for (let i = 0; i < classesNbr; i++) {
      let legendClass = this.config['SYNTHESE']['AREA_AGGREGATION_LEGEND_CLASSES'][i];
      if (i != lastIndex) {
        if (obsNbr > legendClass.min) {
          return legendClass.color;
        }
      } else {
        return legendClass.color;
      }
    }
  }

  toggleStyleFromMap(feature, layer) {
    // restore initial style
    let originStyle = this.areasEnable ? this.originAreasStyle : this.originDefaultStyle;
    let selectedStyle = this.areasEnable ? this.selectedAreasStyle : this.selectedDefaultStyle;

    if (this.selectedLayers.length > 0) {
      this.selectedLayers.forEach((layer) => {
        (layer as L.GeoJSON).setStyle(originStyle);
      });
    }
    // set selected style

    layer.setStyle(selectedStyle);
    this.selectedLayers = [layer];
  }

  private toggleStyleFromList(currentSelectedLayers) {
    // restore inital style
    let originStyle = this.areasEnable ? this.originAreasStyle : this.originDefaultStyle;
    if (this.selectedLayers.length > 0) {
      this.selectedLayers.forEach((layer) => {
        (layer as L.GeoJSON).setStyle(originStyle);
      });
    }
    // Apply new selected layer
    this.selectedLayers = currentSelectedLayers;

    let selectedStyle = this.areasEnable ? this.selectedAreasStyle : this.selectedDefaultStyle;
    this.selectedLayers.forEach((layer) => {
      (layer as L.GeoJSON).setStyle(selectedStyle);
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
      this._commonService.translateToaster('success', 'Map.FileLayerInfoSynthese');
    }
    this.firstFileLayerMessage = false;
  }

  deleteControlValue() {
    this.formService.searchForm.controls.geoIntersection.reset();
  }
}
