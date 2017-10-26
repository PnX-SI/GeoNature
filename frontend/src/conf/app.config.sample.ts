export const AppConfig = {
  appName : 'Geonature 2',
  defaultLanguage:  'fr',
  CAS_AUTHENTIFICATION: true,
  API_ENDPOINT: 'http://127.0.0.1:8000/',
  API_TAXHUB :  'http://127.0.0.1:5000/api/',
  MAP: {
    BASEMAP: [
     {name: 'OpenTopoMap',
     layer: 'http://a.tile.opentopomap.org/{z}/{x}/{y}.png',
     attribution:  '&copy; OpenTopoMap'
     },
     {name: 'OpenStreetMap',
     layer: 'http://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
     attribution: '&copy OpenStreetMap'
     },
     {name: 'GoogleSatellite',
      layer: 'http://{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
      subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
      attribution: '&copy; GoogleMap'
   }
   ],
    CENTER: [46.52863469527167, 2.43896484375],
    ZOOM_LEVEL: 6,
    ZOOM_LEVEL_RELEVE: 15
  }
};


