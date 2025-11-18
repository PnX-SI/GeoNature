import * as geojson from 'geojson';
import * as L from 'leaflet';

/*
Custom overrided GeoJson Layer to control the order of layer in the map
Fix the issue of innacessible point layer overlapped by polygon
*/
export class GeoJSONOverlapped extends L.GeoJSON {
   private _layers: any;
   private _pointFeatureGroup: L.FeatureGroup;
   private _lineFeatureGroup: L.FeatureGroup;
   private _polygonFeatureGroup: L.FeatureGroup;
   public globalFeatureGroup: L.FeatureGroup;

  constructor(geojson: geojson.GeoJsonObject, options?: L.GeoJSONOptions) {
    super(geojson, options);
    this._pointFeatureGroup = new L.FeatureGroup();
    this._lineFeatureGroup = new L.FeatureGroup();
    this._polygonFeatureGroup = new L.FeatureGroup();
    this.globalFeatureGroup = new L.FeatureGroup();
  }

  /*
  The layers of the GeoJSON are set in three separates FeatureGroup which are added to the map in the following order : 
  - polygon
  - line
  - point
  Return a global FeatureGroup which contains the three other (usefull if we want to fitbound to all layers)
  */
  addHierarchizeLayersInMap(map: L.Map): L.FeatureGroup {
    for(let i in this._layers){
      if(this._layers[i].feature.geometry.type == 'Polygon' || this._layers[i].feature.geometry.type == 'MultiPolygon') {
        this._polygonFeatureGroup.addLayer(this._layers[i])
      } else if (this._layers[i].feature.geometry.type == 'Line' || this._layers[i].feature.geometry.type == 'MultiLine') {
        this._lineFeatureGroup.addLayer(this._layers[i])
      }else if (this._layers[i].feature.geometry.type == 'Point' || this._layers[i].feature.geometry.type == 'MultiPoint') {
        this._pointFeatureGroup.addLayer(this._layers[i])
      }
      
    }
    map.addLayer(this._polygonFeatureGroup);
    map.addLayer(this._lineFeatureGroup)
    map.addLayer(this._pointFeatureGroup);

    this.globalFeatureGroup.addLayer(this._pointFeatureGroup);
    this.globalFeatureGroup.addLayer(this._lineFeatureGroup);
    this.globalFeatureGroup.addLayer(this._polygonFeatureGroup);

    return this.globalFeatureGroup;
  }

}
