//import { Injectable } from '@angular/core';
import * as L from 'leaflet';

export class MapUtils {
  constructor(){}

  addCustomLegend(position, id, logoUrl?, func?){
    const LayerControl = L.Control.extend({
      options: {
        position: position
      },
      onAdd: (map) => {
        let customLegend = L.DomUtil.create('div', 'leaflet-bar leaflet-control leaflet-control-custom');
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
          if(func){
            func();
          }
        };
        return customLegend;
      }
    });
    return LayerControl;
  }
}