export const leafletDrawOptions: any = {
  position: 'topleft',
  draw: {
    polyline: false,
    circle: false, // Turns off this drawing tool
    circlemarker: false,
    rectangle: false,
    marker: false,
    polygon: false,
  },
  edit: {
    remove: false,
    moveMarker: true
  }
};
