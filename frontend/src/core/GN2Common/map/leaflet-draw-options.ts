export const leafletDrawOptions = {
  position: 'topleft',
  draw: {
      polyline: {
          shapeOptions: {
              color: '#f357a1',
              weight: 10
          }
      },
      polygon: {
          allowIntersection: false, // Restricts shapes to simple polygons
          drawError: {
              color: '#e1e100', // Color the shape will turn when intersects
              message: 'Intersection forbidden !' // Message that will show when intersect
          },
          shapeOptions: {
              color: '#bada55'
          }
      },
      circle: false, // Turns off this drawing tool
      circlemarker: false,
      rectangle: false,
      marker: false
  },
  edit: {
    remove: true,
    moveMarker: true
  },

};