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
  public legendControl:any;
  public divControl:any;
  public currentNb:any;
  mapForm: FormGroup;

  constructor(public dataService: DataService, public fb: FormBuilder, public mapService: MapService) {
    // Déclaration du formulaire contenant les filtres de la carte
    this.mapForm = fb.group({
      nbClasses: fb.control(null),
      yearMin: fb.control(null),
      yearMax: fb.control(null)
    });    
  }

  ngOnInit() {
    // Initialisation de la fonction "showData"
    this.showData = this.onEachFeatureNbObs;
    // Accès aux données de la BDD GeoNature 
    this.dataService.getCommunes().subscribe(
      (data) => {
        //console.log(data);
        this.myCommunes=data;
        this.background=data;
      }
    );
  }

  ngAfterViewInit(){
    //  this.legendControl =  (L as any).control();
    //  this.legendControl.onAdd = (map) => {
    //   this.divControl = L.DomUtil.create('div','leaflet-controle-title');
    //   this.divControl.innerHTML = '<h3>Coucou</h3>';
    //   //this.legendControl.update();
    //   return this.divControl;
    // };
    // this.legendControl.update = (prop) => {
    //   console.log(prop);
      
    //   this.divControl.innerHTML = "Nombre d'observations" + (prop ? '<b>' + prop.nb_taxon + '</b>' : 'Sélectionner une commune');
    //   console.log(this.divControl);
      
    // };
    // this.legendControl.addTo(this.mapService.map);
    // const LayerControl = L.Control.extend({
    //   options: {
    //     position: 'topleft'
    //   },
    //   onAdd: map => {
    //     this.divControl = L.DomUtil.create(
    //       'div',
    //       'leaflet-bar leaflet-control leaflet-control-custom'
    //     );
    //     this.divControl.innerHTML = '<h3>Coucou</h3>';
    //     return this.divControl;
    //   },
    //   update: prop => {
    //     console.log(prop);
    //     this.divControl.innerHTML = "Nombre d'observations" + (prop ? '<b>' + prop.nb_taxon + '</b>' : 'Sélectionner une commune');
    //     console.log(this.divControl);
    //   }
    // });
    // this.legendControl = new LayerControl();
    // console.log(this.legendControl);
    
    // this.mapService.map.addControl(this.legendControl);
    //this.legendControl.onAdd(this.mapService.map);
    // const GPSLegend = this.mapService.addCustomLegend('topleft', 'GPSLegend');
    // GPSLegend.update = () => {
    //   console.log('UPDATE')
    // }
    // this.mapService.map.addControl(new GPSLegend());
  }

  // Afficher les données relatives au nombre de taxons
  changeMapToTax() {   
    this.myCommunes = Object.assign({}, this.myCommunes);
    this.showData = this.onEachFeatureNbTax.bind(this);
  }

  // Afficher les données relatives au nombre d'observations
  changeMapToObs() {   
    this.myCommunes = Object.assign({}, this.myCommunes);
    this.showData = this.onEachFeatureNbObs.bind(this);
  }

  // Rafraichissement des données en fonction des filtres renseignés par l'utilisateur
  refreshData() {
    this.dataService.getCommunes(this.mapForm.value).subscribe(
      (data) => {
        this.myCommunes=data;
      }
    );
  }

  // Communes grisées si pas de données concernant une certaine année
  defineBackground(feature, layer) {
    layer.setStyle({fillColor: 'rgb(150, 150, 150)', color: 'rgb(255, 255, 255)', fillOpacity: 0.9});
    layer.bindPopup("<h5>"+feature.properties.area_name+"</h5>");
    layer.on({
      mouseover: this.highlightFeature.bind(this),
      mouseout: this.resetHighlight,
      click: this.zoomToFeature.bind(this)
    });
  };

  // Paramètres de la carte relative au nombre d'observations
  onEachFeatureNbObs(feature, layer) {
    layer.setStyle({fillColor: this.getColorObs(feature.properties.nb_obs), color: this.initialBorderColor, fillOpacity: 0.9});
    //layer.bindPopup("<h5>"+feature.properties.area_name+"</h5><b>Nombre d'observations :</b> "+feature.properties.nb_obs);
    layer.on('click', (e)=> {
      console.log(e);
      console.log(e.target.feature.geometry.properties);
      
      //this.legendControl.update(e.target.feature.geometry.properties)
      this.currentNb = e.target.feature.geometry.properties.nb_obs;
      
    })
    // layer.on({
    //   mouseover: this.highlightFeature,
    //   mouseout: this.resetHighlight,
    //   click: this.zoomToFeature.bind(this)
    // });
  };

  // Paramètres de la carte relative au nombre de taxons
  onEachFeatureNbTax(feature, layer) {
    layer.setStyle({fillColor: this.getColorTax(feature.properties.nb_taxon), color: this.initialBorderColor, fillOpacity: 0.9});
    layer.bindPopup("<h5>"+feature.properties.area_name+"</h5><b>Nombre de taxons :</b> "+feature.properties.nb_taxon);



    layer.on({
      mouseover: this.highlightFeature.bind(this),
      mouseout: this.resetHighlight,
      click: this.zoomToFeature.bind(this)
    });
  };

  // Couleurs de la carte relative au nombre d'observations
  getColorObs(obs) {
    return  obs > 10000 ? "rgb(48, 2, 18)":
            obs > 5000  ? "rgb(107, 3, 41)":
            obs > 4000  ? "rgb(173, 4, 47)":
            obs > 3000  ? "rgb(221, 102, 8)":
            obs > 2000  ? "rgb(233, 164, 27)":
            obs > 1000  ? "rgb(236, 212, 123)":
                          "rgb(232, 229, 202)";
  }

  // Couleurs de la carte relative au nombre d'observations
  getColorTax(tax) {
    return  tax > 1500 ?  "rgb(8, 21, 3)":
            tax > 1200 ?  "rgb(22, 44, 8)":
            tax > 900  ?  "rgb(51, 84, 29)":
            tax > 600  ?  "rgb(104, 143, 79)":
            tax > 300  ?  "rgb(160, 191, 139)":
                          "rgb(206, 226, 193)";
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
    this.legendControl.update(layer.feature.properties);
  }

  // Réinitialiser l'aspect de la commune lorsque la souris n'est plus dessus
  resetHighlight(e) {
    const layer = e.target;
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
