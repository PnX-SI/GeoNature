export const leafletDrawOption: any = {
  position: 'topleft',
  draw: {
    polyline: true,
    circle: false, // Turns off this drawing tool
    circlemarker: false,
    rectangle: false,
    marker: false,
    polygon: {
      allowIntersection: false, // Restricts shapes to simple polygons
      drawError: {
        color: '#e1e100', // Color the shape will turn when intersects
        message: 'Intersection forbidden !' // Message that will show when intersect
      }
    }
  },
  edit: {
    remove: false,
    moveMarker: true
  }
};
