import { Component, OnInit, AfterViewInit } from "@angular/core";
import { FormBuilder, FormGroup } from "@angular/forms";
import { MapService } from "@geonature_common/map/map.service";
import * as L from 'leaflet';
// Services
import { DataService } from "../services/data.services";

@Component({
  selector: "dashboard-maps",
  templateUrl: "dashboard-maps.component.html",
  styleUrls: ['./dashboard-maps.component.scss'],
  providers: [MapService]
})

export class DashboardMapsComponent implements OnInit, AfterViewInit {
  
  public background: Array<any>;
  public myCommunes: Array<any>;
  public showData: Function;
  public initialBorderColor = 'rgb(255, 255, 255)';
  public selectedBorderColor = 'rgb(50, 50, 50)';
  public obsColors = [
    ["#BE8096", "#64112E"],
    ["#D4AAB9", "#89173F", "#320917"],
    ["#D4AAB9", "#9E4161", "#64112E", "#260712"],
    ["#E9D4DC", "#B36B84", "#89173F", "#4B0D23", "#19050C"],
    ["#E9D4DC", "#C995A7", "#9E4161", "#711334", "#3F0B1D", "#0D0306"],
    ["#E9D4DC", "#C995A7", "#A95673", "#89173F", "#64112E", "#3F0B1D", "#19050C"],
    ["#F4E9ED", "#DEBFCA", "#BE8096", "#9E4161", "#7D153A", "#580F29", "#320917", "#0D0306"],
    ["#F4E9ED", "#DEBFCA", "#BE8096", "#9E4161", "#89173F", "#64112E", "#3F0B1D", "#260712", "#0D0306"],
    ["#F4E9ED", "#DEBFCA", "#BE8096", "#9E4161", "#89173F", "#711334", "#580F29", "#3F0B1D", "#260712", "#0D0306"]
  ];
  public taxColors = [
    ["#8AB2B2", "#1E5454"],
    ["#B1CCCC", "#297373", "#0F2A2A"],
    ["#B1CCCC", "#4F8C8C", "#1E5454", "#0C2020"],
    ["#D8E5E5", "#76A5A5", "#297373", "#173F3F", "#081515"],
    ["#D8E5E5", "#9DBFBF", "#4F8C8C", "#225F5F", "#133535", "#040B0B"],
    ["#D8E5E5", "#9DBFBF", "#639999", "#297373", "#1E5454", "#133535", "#081515"],
    ["#EBF2F2", "#C4D8D8", "#8AB2B2", "#4F8C8C", "#266969", "#1B4A4A", "#0F2A2A", "#040B0B"],
    ["#EBF2F2", "#C4D8D8", "#8AB2B2", "#4F8C8C", "#297373", "#1E5454", "#133535", "#0C2020", "#040B0B"],
    ["#EBF2F2", "#C4D8D8", "#8AB2B2", "#4F8C8C", "#297373", "#225F5F", "#1B4A4A", "#133535", "#0C2020", "#040B0B"]
  ];
  public legend: any;
  public divLegendObs: any;
  public divLegendTax: any;
  public intro = "Placez la souris sur une commune";
  public currentMap: any;
  public currentCommune: any;
  public currentNbObs: any;
  public currentNbTax: any;
  public currentNbClasses: any;
  mapForm: FormGroup;

  public test: any;

  constructor(public dataService: DataService, public fb: FormBuilder, public mapService: MapService) {
    // Déclaration du formulaire contenant les filtres de la carte
    this.mapForm = fb.group({
      nbClasses: fb.control(null),
      yearMin: fb.control(null),
      yearMax: fb.control(null)
    });

    // Initialisation des variables formant la légende
    this.divLegendObs = L.DomUtil.create('div', 'divLegend');
    this.divLegendObs.innerHTML += "<b>Nombre d'observations</b><br/>";
    const gradesObs = [0, 1000, 2000, 3000, 4000, 5000, 10000];
    for(var i=0; i<gradesObs.length; i++) {
      this.divLegendObs.innerHTML += '<i style="background:' + this.getColorObs(gradesObs[i]+1) + '"></i>' + gradesObs[i] + (gradesObs[i+1] ? '&ndash;' + gradesObs[i + 1] + '<br>' : '+');
    }
    
    this.divLegendTax = L.DomUtil.create('div', 'divLegend');
    this.divLegendTax.innerHTML += "<b>Nombre de taxons</b><br/>";
    const gradesTax = [0, 300, 600, 900, 1200, 1500];
    for(var i=0; i<gradesTax.length; i++) {
      this.divLegendTax.innerHTML += '<i style="background:' + this.getColorTax(gradesTax[i]+1) + '"></i>' + gradesTax[i] + (gradesTax[i+1] ? '&ndash;' + gradesTax[i + 1] + '<br>' : '+');
    }

  }

  ngOnInit() {
    // Initialisation de la fonction "showData"
    this.showData = this.onEachFeatureNbObs;
    // Accès aux données de la BDD GeoNature 
    this.dataService.getCommunes().subscribe(
      (data) => {
        this.myCommunes=data;
        this.background=data;
      }
    );
    this.currentMap = 1;
    console.log(this.mapForm.value.nbClasses);
  }

  ngAfterViewInit(){
    // Implémentation de la légende
    this.legend = (L as any).control({position: "bottomright"});
    this.legend.onAdd = (map) => {
      return this.divLegendObs;
    };
    this.legend.addTo(this.mapService.map);
  //   this.legendControl =  (L as any).control();
  //   this.legendControl.onAdd = (map) => {
  //     this.divControl = L.DomUtil.create('div','leaflet-controle-title');
  //     this.divControl.innerHTML = '<h3>Coucou</h3>';
  //     //this.legendControl.update();
  //     return this.divControl;
  //   };
  //   this.legendControl.update = (prop) => {
  //     console.log(prop);      
  //     this.divControl.innerHTML = "Nombre d'observations" + (prop ? '<b>' + prop.nb_taxon + '</b>' : 'Sélectionner une commune');
  //     console.log(this.divControl);      
  //   };
  //   this.legendControl.addTo(this.mapService.map);
  //   const LayerControl = L.Control.extend({
  //     options: {
  //       position: 'topleft'
  //     },
  //     onAdd: map => {
  //       this.divControl = L.DomUtil.create(
  //         'div',
  //         'leaflet-bar leaflet-control leaflet-control-custom'
  //       );
  //       this.divControl.innerHTML = '<h3>Coucou</h3>';
  //       return this.divControl;
  //     },
  //     update: prop => {
  //       console.log(prop);
  //       this.divControl.innerHTML = "Nombre d'observations" + (prop ? '<b>' + prop.nb_taxon + '</b>' : 'Sélectionner une commune');
  //       console.log(this.divControl);
  //     }
  //   });
  //   this.legendControl = new LayerControl();
  //   console.log(this.legendControl);
    
  //   this.mapService.map.addControl(this.legendControl);
  //   this.legendControl.onAdd(this.mapService.map);
  //   const GPSLegend = this.mapService.addCustomLegend('topleft', 'GPSLegend');
  //   GPSLegend.update = () => {
  //     console.log('UPDATE')
  //   }
  //   this.mapService.map.addControl(new GPSLegend());
  }

  // Afficher les données relatives au nombre de taxons
  changeMapToTax() {   
    this.myCommunes = Object.assign({}, this.myCommunes);
    this.showData = this.onEachFeatureNbTax.bind(this);
    this.mapService.map.removeControl(this.legend);
    this.legend.onAdd = (map) => {
      return this.divLegendTax;
    };
    this.legend.addTo(this.mapService.map);
    this.currentMap = 2;
  }

  // Afficher les données relatives au nombre d'observations
  changeMapToObs() {   
    this.myCommunes = Object.assign({}, this.myCommunes);
    this.showData = this.onEachFeatureNbObs.bind(this);
    this.mapService.map.removeControl(this.legend);
    this.legend.onAdd = (map) => {
      return this.divLegendObs;
    };
    this.legend.addTo(this.mapService.map);
    this.currentMap = 1;
  }

  // Rafraichissement des données en fonction des filtres renseignés par l'utilisateur
  refreshData() {
    console.log(this.mapForm.value.nbClasses);
    this.dataService.getCommunes(this.mapForm.value).subscribe(
      (data) => {
        this.myCommunes=data;
      }
    );
  }

  // Communes grisées si pas de données concernant une certaine année
  defineBackground(feature, layer) {
    layer.setStyle({fillColor: 'rgb(150, 150, 150)', color: 'rgb(255, 255, 255)', fillOpacity: 0.9});
    //layer.bindPopup("<h5>"+feature.properties.area_name+"</h5>");
    layer.on({
      mouseover: this.highlightFeatureBackground.bind(this),
      mouseout: this.resetHighlight.bind(this),
      click: this.zoomToFeature.bind(this)
    });
  };

  // Paramètres de la carte relative au nombre d'observations
  onEachFeatureNbObs(feature, layer) {
    layer.setStyle({fillColor: this.getColorObs(feature.properties.nb_obs), color: this.initialBorderColor, fillOpacity: 0.9});   
    layer.on({
      mouseover: this.highlightFeature.bind(this),
      mouseout: this.resetHighlight.bind(this),
      click: this.zoomToFeature.bind(this)
    });
    // layer.on('click', (e) => {
    //   console.log(e);
    //   console.log(e.target.feature.geometry.properties);      
    //   this.legendControl.update(e.target.feature.geometry.properties)
    //   this.currentNb = e.target.feature.geometry.properties.nb_obs;      
    // })
  };

  // Paramètres de la carte relative au nombre de taxons
  onEachFeatureNbTax(feature, layer) {
    layer.setStyle({fillColor: this.getColorTax(feature.properties.nb_taxon), color: this.initialBorderColor, fillOpacity: 0.9});
    layer.on({
      mouseover: this.highlightFeature.bind(this),
      mouseout: this.resetHighlight.bind(this),
      click: this.zoomToFeature.bind(this)
    });
  };

  // Couleurs de la carte relative au nombre d'observations
  getColorObs(obs) {
    var nb_classes = 7;
    if (this.mapForm.value.nbClasses) {
      nb_classes = this.mapForm.value.nbClasses;
    }
    const gradesObs = [1000, 2000, 3000, 4000, 5000, 10000];
    for (var i=0; i < nb_classes-1; i++) {
      if (obs < gradesObs[i]) {
        return this.obsColors[nb_classes-2][i];
      }
    }
    return this.obsColors[nb_classes-2][nb_classes-1];
  }

  // Couleurs de la carte relative au nombre d'observations
  getColorTax(tax) {
    var nb_classes = 7;
    if (this.mapForm.value.nbClasses) {
      nb_classes = this.mapForm.value.nbClasses;
    }
    const gradesTax = [300, 600, 900, 1200, 1500];
    for (var i=0; i < nb_classes-1; i++) {
      if (tax < gradesTax[i]) {
        return this.taxColors[nb_classes-2][i];
      }
    }
    return this.taxColors[nb_classes-2][nb_classes-1];
  }

  // Changer l'aspect de la commune lorsque la souris passe dessus
  highlightFeature(e) {    
    const layer = e.target;
    layer.setStyle({
      //color: this.selectedBorderColor,
      color: "rgb(50, 50, 50)",
      weight: 7,
      fillOpacity: 1
    });
    layer.bringToFront();
    this.intro = null;
    this.currentCommune = layer.feature.geometry.properties.area_name;
    if (this.currentMap == 1) {
      this.currentNbObs = "Nombre d'observations : " + layer.feature.geometry.properties.nb_obs;
    }
    else if (this.currentMap == 2) {
      this.currentNbTax = "Nombre de taxons : " + layer.feature.geometry.properties.nb_taxon; 
    }
  }

  // Changer l'aspect de la commune lorsque la souris passe dessus
  highlightFeatureBackground(e) {    
    const layer = e.target;
    layer.setStyle({
      //color: this.selectedBorderColor,
      color: "rgb(50, 50, 50)",
      weight: 7,
      fillOpacity: 1
    });
    layer.bringToFront();
    this.intro = null;
    this.currentCommune = layer.feature.geometry.properties.area_name;
    if (this.currentMap == 1) {
      this.currentNbObs = "Nombre d'observations : 0";
    }
    else if (this.currentMap == 2) {
      this.currentNbTax = "Nombre de taxons : 0"; 
    }
  }

  // Réinitialiser l'aspect de la commune lorsque la souris n'est plus dessus
  resetHighlight(e) {
    const layer = e.target;
    this.intro = "Placez la souris sur une commune";
    this.currentCommune = null;
    this.currentNbObs = null;
    this.currentNbTax = null;
    layer.setStyle({
      color: this.initialBorderColor,
      weight: 3,
      fillOpacity: 0.9
    });
  }

  // Zoomer sur une commune en cliquant dessus
  zoomToFeature(e) {
    this.mapService.map.fitBounds(e.target.getBounds());
  }

}
