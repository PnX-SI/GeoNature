import * as L from 'leaflet';

export class MapUtils {
  constructor() {}

  addCustomLegend(position, id, logoUrl?, func?) {
    const LayerControl = L.Control.extend({
      options: {
        position: position
      },
      onAdd: (map) => {
        const customLegend = L.DomUtil.create('div', 'leaflet-bar leaflet-control leaflet-control-custom');
        customLegend.id = id;
        customLegend.style.width = '34px';
        customLegend.style.height = '34px';
        customLegend.style.lineHeight = '30px';
        customLegend.style.backgroundColor = 'white';
        customLegend.style.cursor = 'pointer';
        customLegend.style.border = '2px solid rgba(0,0,0,0.2)';
        customLegend.style.backgroundImage = logoUrl;
        customLegend.style.backgroundRepeat = 'no-repeat';
        customLegend.style.backgroundPosition = '7px';

        customLegend.onclick = () => {
          if (func) {
            func();
          }
        };
        return customLegend;
      }
    });
    return LayerControl;
  }

  createMarker(x, y) {
   return L.marker([y, x], {
      icon: L.icon({
              iconUrl: require<any>('../../../../node_modules/leaflet/dist/images/marker-icon.png'),
              iconSize: [24, 36],
              iconAnchor: [12, 36]
      }),
      draggable: true,
  })
  }

  removeAllLayers(map, featureGroup){
    featureGroup.eachLayer((layer)=>{
      map.removeLayer(layer);
    })
  }

}
