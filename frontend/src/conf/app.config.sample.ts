export const AppConfig = {
  appName : 'Geonature 2',
  defaultLanguage:  'fr',
  URL_APPLICATION: 'http://127.0.0.1:4200',
  API_ENDPOINT: 'http://127.0.0.1:8000/',
  API_TAXHUB:  'http://127.0.0.1:5000/api/',
  ID_APPLICATION_GEONATURE: 14,
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
  },
  // Spécifique à l'instance ministérielle de GeoNature concernant l'autentification via le CAS de l'INPN
  CAS: {
    CAS_AUTHENTIFICATION: false,
    CAS_LOGIN_URL: 'https://inpn.mnhn.fr/auth/login',
    CAS_URL_LOGOUT: 'https://inpn.mnhn.fr/auth/login',
    CAS_VALIDATION_URL: 'https://inpn.mnhn.fr/auth/serviceValidate'
  },
    // Porté des droits
    RIGHTS: {
      'NOTHING': 0,
      'MY_DATA': 1,
      'MY_ORGANISM_DATA': 2,
      'ALL_DATA': 3
    }
};
