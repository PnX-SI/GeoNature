import * as L from 'leaflet'
var customMarker = L.Icon.extend({
  options: {
    shadowUrl: null,
    iconAnchor: new L.Point(12, 12),
    iconSize: new L.Point(24, 24),
    iconUrl: require<any>('../../../../node_modules/leaflet/dist/images/marker-icon.png')
  }
});

export const leafletDrawOption: any = {
  position: 'topleft',
  draw: {
    polyline: true,
    circle: false, // Turns off this drawing tool
    circlemarker: false,
    rectangle: false,
    marker: {
      icon: new customMarker()
    },
    polygon: {
      allowIntersection: false, // Restricts shapes to simple polygons
      drawError: {
        color: '#e1e100', // Color the shape will turn when intersects
        message: 'Intersection forbidden !' // Message that will show when intersect
      },
    },

  },
  edit: {
    remove: false,
    moveMarker: true
  }
};
