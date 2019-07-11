import { Component, OnInit, OnChanges, AfterViewInit, Input } from "@angular/core";
import { FormBuilder, FormGroup } from "@angular/forms";
import { MapService } from "@geonature_common/map/map.service";
import * as L from 'leaflet';
import { AppConfig } from '@geonature_config/app.config';
// Services
import { DataService } from "../services/data.services";

@Component({
  selector: "dashboard-maps",
  templateUrl: "dashboard-maps.component.html",
  styleUrls: ['./dashboard-maps.component.scss'],
  providers: [MapService]
})

export class DashboardMapsComponent implements OnInit, OnChanges, AfterViewInit {

  public background: Array<any>;
  public myCommunes: Array<any>;
  public showData: Function;
  public initialBorderColor = 'rgb(255, 255, 255)';
  public selectedBorderColor = 'rgb(50, 50, 50)';
  public obsColors: { [nbClasses: string]: any } = {
    2: ["#BE8096", "#64112E"],
    3: ["#D4AAB9", "#89173F", "#320917"],
    4: ["#D4AAB9", "#9E4161", "#64112E", "#260712"],
    5: ["#E9D4DC", "#B36B84", "#89173F", "#4B0D23", "#19050C"],
    6: ["#E9D4DC", "#C995A7", "#9E4161", "#711334", "#3F0B1D", "#0D0306"],
    7: ["#E9D4DC", "#C995A7", "#A95673", "#89173F", "#64112E", "#3F0B1D", "#19050C"],
    8: ["#F4E9ED", "#DEBFCA", "#BE8096", "#9E4161", "#7D153A", "#580F29", "#320917", "#0D0306"],
    9: ["#F4E9ED", "#DEBFCA", "#BE8096", "#9E4161", "#89173F", "#64112E", "#3F0B1D", "#260712", "#0D0306"],
    10: ["#F4E9ED", "#DEBFCA", "#BE8096", "#9E4161", "#89173F", "#711334", "#580F29", "#3F0B1D", "#260712", "#0D0306"]
  };
  public taxColors: { [nbClasses: string]: any } = {
    2: ["#8AB2B2", "#1E5454"],
    3: ["#B1CCCC", "#297373", "#0F2A2A"],
    4: ["#B1CCCC", "#4F8C8C", "#1E5454", "#0C2020"],
    5: ["#D8E5E5", "#76A5A5", "#297373", "#173F3F", "#081515"],
    6: ["#D8E5E5", "#9DBFBF", "#4F8C8C", "#225F5F", "#133535", "#040B0B"],
    7: ["#D8E5E5", "#9DBFBF", "#639999", "#297373", "#1E5454", "#133535", "#081515"],
    8: ["#EBF2F2", "#C4D8D8", "#8AB2B2", "#4F8C8C", "#266969", "#1B4A4A", "#0F2A2A", "#040B0B"],
    9: ["#EBF2F2", "#C4D8D8", "#8AB2B2", "#4F8C8C", "#297373", "#1E5454", "#133535", "#0C2020", "#040B0B"],
    10: ["#EBF2F2", "#C4D8D8", "#8AB2B2", "#4F8C8C", "#297373", "#225F5F", "#1B4A4A", "#133535", "#0C2020", "#040B0B"]
  };
  public legend: any;
  public divLegendObs: any;
  public divLegendTax: any;
  public introLegend = "Placez la souris sur une commune";
  public currentMap: any;
  public currentCommune: any;
  public currentNbObs: any;
  public currentNbTax: any;

  mapForm: FormGroup;
  public filter: any;
  @Input() taxonomies: any;
  @Input() yearsMinMax: any;
  public yearRange = [1980, 2019];
  currentCdRef: any;
  public filtersDict: any;

  public taxonApiEndPoint = `${AppConfig.API_ENDPOINT}/synthese/taxons_autocomplete`;

  constructor(public dataService: DataService, public fb: FormBuilder, public mapService: MapService) {
    // Déclaration du formulaire contenant les filtres de la carte
    this.mapForm = fb.group({
      // nbClasses: fb.control(null),
      selectedYearRange: fb.control(this.yearRange),
      selectedFilter: fb.control(null),
      selectedRegne: fb.control(null),
      selectedPhylum: fb.control(null),
      selectedClasse: fb.control(null),
      selectedOrdre: fb.control(null),
      selectedFamille: fb.control(null),
      selectedGroup1INPN: fb.control(null),
      selectedGroup2INPN: fb.control(null),
      taxon: fb.control(null)
    });

    // Initialisation des variables formant la légende
    //// Légende concernant le nombre d'observations
    this.divLegendObs = L.DomUtil.create('div', 'divLegend');
    this.divLegendObs.innerHTML += "<b>Nombre d'observations</b><br/>";
    const gradesObs = [1, 1000, 2000, 3000, 4000, 5000, 10000];
    for (var i = 0; i < gradesObs.length; i++) {
      this.divLegendObs.innerHTML += '<i style="background:' + this.getColorObs(gradesObs[i] + 1) + '"></i>' + gradesObs[i] + (gradesObs[i + 1] ? '&ndash;' + gradesObs[i + 1] + '<br>' : '+');
    }
    //// Légende concernant le nombre de taxons
    this.divLegendTax = L.DomUtil.create('div', 'divLegend');
    this.divLegendTax.innerHTML += "<b>Nombre de taxons</b><br/>";
    const gradesTax = [1, 100, 200, 300, 400, 500, 600];
    for (var i = 0; i < gradesTax.length; i++) {
      this.divLegendTax.innerHTML += '<i style="background:' + this.getColorTax(gradesTax[i] + 1) + '"></i>' + gradesTax[i] + (gradesTax[i + 1] ? '&ndash;' + gradesTax[i + 1] + '<br>' : '+');
    }
  }

  ngOnInit() {
    // Initialisation de la fonction "showData" (au chargement de la page, la carte affiche automatiquement le nombre d'observations)
    this.showData = this.onEachFeatureNbObs;
    // Accès aux données de synthèse de la BDD GeoNature 
    this.dataService.getDataCommunes().subscribe(
      (data) => {
        // console.log(data);
        this.myCommunes = data;
        this.background = data;
      }
    );
    // Initialisation de la variable currentMap (au chargement de la page, la carte affiche automatiquement le nombre d'observations)
    this.currentMap = 1; // Permet d'afficher les informations de légende associées au nombre d'observations
  }

  ngOnChanges(change) {
    // Récupération des années min et max présentes dans les données de synthèse de la BDD GeoNature
    if (change.yearsMinMax && change.yearsMinMax.currentValue != undefined) {
      this.yearRange = change.yearsMinMax.currentValue;
    }
  }

  ngAfterViewInit() {
    // Implémentation de la légende (au chargement de la page, la carte affiche automatiquement le nombre d'observations)
    this.legend = (L as any).control({ position: "bottomright" });
    this.legend.onAdd = (map) => {
      return this.divLegendObs;
    };
    this.legend.addTo(this.mapService.map);
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
    this.currentMap = 2; // Permet d'afficher les informations de légende associées au nombre de taxons
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
    this.currentMap = 1; // Permet d'afficher les informations de légende associées au nombre d'observations
  }

  // Rafraichissement des données en fonction des filtres renseignés par l'utilisateur
  onTaxFilterChange(event) {
    // Déterminer le type de filtre taxonomique qui a été sélectionné pour afficher la liste déroulante adéquate
    this.filter = event.target.value;
    // Réinitialiser l'ancien filtre qui a été sélectionné pour empêcher les erreurs de requête
    this.mapForm.controls["selectedGroup1INPN"].reset();
    this.mapForm.controls["selectedGroup2INPN"].reset();
    this.mapForm.controls["selectedRegne"].reset();
    this.mapForm.controls["selectedPhylum"].reset();
    this.mapForm.controls["selectedClasse"].reset();
    this.mapForm.controls["selectedOrdre"].reset();
    this.mapForm.controls["selectedFamille"].reset();
    this.mapForm.controls["taxon"].reset();
    console.log(this.mapForm.value);
    // Afficher les données d'origine si la valeur vaut ""
    if (this.filter == "") {
      this.dataService.getDataCommunes(this.mapForm.value).subscribe(
        (data) => {
          this.myCommunes = data;
        }
      );
    }
  }
  getCurrentParameters(event) {
    // console.log(event);
    console.log(this.filter);
    console.log(this.mapForm.value);
    // Copie des éléments du formulaire pour pouvoir y ajouter cd_ref s'il s'agit d'un filtre par taxon
    this.filtersDict = Object.assign({}, this.mapForm.value);
    // S'il s'agit d'une recherche de taxon...
    if (this.filter == 'Taxon') {
      if (event.item) {
        // Récupération du cd_ref
        var cd_ref = event.item.cd_ref;
        // Enregistrement du cd_ref pour un potentiel changement de période concernant un taxon
        this.currentCdRef = cd_ref;
      }
      else {
        // Récupération du cd_ref pour un changement de période concernant un taxon
        var cd_ref = this.currentCdRef;
      }
      // Ajout de cd_ref à la liste des paramètres de la requête
      this.filtersDict["taxon"] = cd_ref;
    }
    // console.log(this.filtersDict);
    // Accès aux données de synthèse de la BDD GeoNature
    this.dataService.getDataCommunes(this.filtersDict).subscribe(
      (data) => {
        this.myCommunes = data;
      }
    );
  }

  // Communes grisées si pas de données concernant une certaine année
  defineBackground(feature, layer) {
    layer.setStyle({ fillColor: 'rgb(150, 150, 150)', color: 'rgb(255, 255, 255)', fillOpacity: 0.9 });
    layer.on({
      mouseover: this.highlightFeatureBackground.bind(this),
      mouseout: this.resetHighlight.bind(this),
      click: this.zoomToFeature.bind(this)
    });
  };

  // Paramètres de la carte relative au nombre d'observations
  onEachFeatureNbObs(feature, layer) {
    layer.setStyle({ fillColor: this.getColorObs(feature.properties.nb_obs), color: this.initialBorderColor, fillOpacity: 0.9 });
    layer.on({
      mouseover: this.highlightFeature.bind(this),
      mouseout: this.resetHighlight.bind(this),
      click: this.zoomToFeature.bind(this)
    });
  };

  // Paramètres de la carte relative au nombre de taxons
  onEachFeatureNbTax(feature, layer) {
    layer.setStyle({ fillColor: this.getColorTax(feature.properties.nb_taxons), color: this.initialBorderColor, fillOpacity: 0.9 });
    layer.on({
      mouseover: this.highlightFeature.bind(this),
      mouseout: this.resetHighlight.bind(this),
      click: this.zoomToFeature.bind(this)
    });
  };

  // Couleurs de la carte relative au nombre d'observations
  getColorObs(obs) {
    var nb_classes = 7;
    const gradesObs = [1000, 2000, 3000, 4000, 5000, 10000];
    for (var i = 0; i < nb_classes - 1; i++) {
      if (obs < gradesObs[i]) {
        return this.obsColors[nb_classes][i];
      }
    }
    return this.obsColors[nb_classes][nb_classes - 1];
  }

  // Couleurs de la carte relative au nombre de taxons
  getColorTax(tax) {
    var nb_classes = 7;
    const gradesTax = [100, 200, 300, 400, 500, 600];
    for (var i = 0; i < nb_classes - 1; i++) {
      if (tax < gradesTax[i]) {
        return this.taxColors[nb_classes][i];
      }
    }
    return this.taxColors[nb_classes][nb_classes - 1];
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
    this.introLegend = null;
    this.currentCommune = layer.feature.geometry.properties.area_name;
    if (this.currentMap == 1) {
      this.currentNbObs = "Nombre d'observations : " + layer.feature.geometry.properties.nb_obs;
    }
    else if (this.currentMap == 2) {
      this.currentNbTax = "Nombre de taxons : " + layer.feature.geometry.properties.nb_taxons;
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
    this.introLegend = null;
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
    this.introLegend = "Placez la souris sur une commune";
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
