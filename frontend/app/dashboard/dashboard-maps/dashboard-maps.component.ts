import {
  Component,
  OnInit,
  OnChanges,
  AfterViewInit,
  Input,
  ViewEncapsulation
} from "@angular/core";
import { FormBuilder, FormGroup, FormControl } from "@angular/forms";
import { MapService } from "@geonature_common/map/map.service";
import * as L from "leaflet";
import { AppConfig } from "@geonature_config/app.config";
import { ModuleConfig } from "../../module.config";
// Services
import { DataService } from "../services/data.services";

@Component({
  selector: "dashboard-maps",
  templateUrl: "dashboard-maps.component.html",
  ViewEncapsulation: ViewEncapsulation.None,
  styleUrls: ["./dashboard-maps.component.scss"],
  providers: [MapService]
})
export class DashboardMapsComponent implements OnInit, OnChanges, AfterViewInit {

  // Tableau contenant la géométrie et les données des zonages
  public myAreas: Array<any>;
  // Fonction permettant d'afficher les zonages sur la carte (leaflet)
  public showData: Function;
  // Degré de simplication des zonages
  public simplifyLevel = ModuleConfig.SIMPLIFY_LEVEL;
  // Bornes pour la représentation en nombre d'observations
  public gradesObs = ModuleConfig.BORNE_OBS;
  // Bornes pour la représentation en nombre de taxons
  public gradesTax = ModuleConfig.BORNE_TAXON;
  // Couleurs de bordure des zonages
  public initialBorderColor = "rgb(255, 255, 255)";
  public selectedBorderColor = "rgb(50, 50, 50)";
  // Couleurs de remplissage des zonages pour la représentation en nombre d'observations
  public obsColors: { [nbClasses: string]: any } = {
    2: ["#BE8096", "#64112E"],
    3: ["#D4AAB9", "#89173F", "#320917"],
    4: ["#D4AAB9", "#9E4161", "#64112E", "#260712"],
    5: ["#E9D4DC", "#B36B84", "#89173F", "#4B0D23", "#19050C"],
    6: ["#E9D4DC", "#C995A7", "#9E4161", "#711334", "#3F0B1D", "#0D0306"],
    7: [
      "#E9D4DC",
      "#C995A7",
      "#A95673",
      "#89173F",
      "#64112E",
      "#3F0B1D",
      "#19050C"
    ],
    8: [
      "#F4E9ED",
      "#DEBFCA",
      "#BE8096",
      "#9E4161",
      "#7D153A",
      "#580F29",
      "#320917",
      "#0D0306"
    ],
    9: [
      "#F4E9ED",
      "#DEBFCA",
      "#BE8096",
      "#9E4161",
      "#89173F",
      "#64112E",
      "#3F0B1D",
      "#260712",
      "#0D0306"
    ],
    10: [
      "#F4E9ED",
      "#DEBFCA",
      "#BE8096",
      "#9E4161",
      "#89173F",
      "#711334",
      "#580F29",
      "#3F0B1D",
      "#260712",
      "#0D0306"
    ]
  };
  // Couleurs de remplissage des zonages pour la représentation en nombre de taxons
  public taxColors: { [nbClasses: string]: any } = {
    2: ["#8AB2B2", "#1E5454"],
    3: ["#B1CCCC", "#297373", "#0F2A2A"],
    4: ["#B1CCCC", "#4F8C8C", "#1E5454", "#0C2020"],
    5: ["#D8E5E5", "#76A5A5", "#297373", "#173F3F", "#081515"],
    6: ["#D8E5E5", "#9DBFBF", "#4F8C8C", "#225F5F", "#133535", "#040B0B"],
    7: [
      "#D8E5E5",
      "#9DBFBF",
      "#639999",
      "#297373",
      "#1E5454",
      "#133535",
      "#081515"
    ],
    8: [
      "#EBF2F2",
      "#C4D8D8",
      "#8AB2B2",
      "#4F8C8C",
      "#266969",
      "#1B4A4A",
      "#0F2A2A",
      "#040B0B"
    ],
    9: [
      "#EBF2F2",
      "#C4D8D8",
      "#8AB2B2",
      "#4F8C8C",
      "#297373",
      "#1E5454",
      "#133535",
      "#0C2020",
      "#040B0B"
    ],
    10: [
      "#EBF2F2",
      "#C4D8D8",
      "#8AB2B2",
      "#4F8C8C",
      "#297373",
      "#225F5F",
      "#1B4A4A",
      "#133535",
      "#0C2020",
      "#040B0B"
    ]
  };
  // Encart pour la légende de la carte
  public legend: any;
  // Légende pour la représentation en nombre d'observations
  public divLegendObs: any;
  // Légende pour la représentation en nombre de taxons
  public divLegendTax: any;
  // Chaîne de caractères permettant de gérer le contenu de la légende dynamiquement
  public introLegend = "Placez la souris sur un zonage";
  // Stocker le type de représentation qui a été sélectionné en dernier #1 nb d'observations #2 nb de taxons
  public currentMap = 1 // par défaut, la carte affiche automatiquement le nombre d'observations
  // Stocker le nom du zonage sur lequel la souris est posée
  public currentArea: any;
  // Stocker le nb d'observations du zonage sur lequel la souris est posée
  public currentNbObs: any;
  // Stocker le nb de taxons du zonage sur lequel la souris est posée
  public currentNbTax: any;
  // Stocker le cd_ref du taxon qui a été sélectionné en dernier
  public currentCdRef: any;

  // Gestion du formulaire général
  mapForm: FormGroup;
  @Input() taxonomies: any;
  @Input() yearsMinMax: any;
  public yearRange = [0, 2019];
  public filtersDict: any;
  public filter: any;
  public disabledTaxButton = false;
  public tabAreasTypes: Array<any>;

  // Gestion du formulaire contrôlant le type de zonage
  public areaTypeControl = new FormControl('COM');
  public currentTypeCode = "COM"; // par défaut, la carte s'affiche automatiquement en mode "communes"

  // Pouvoir stoppper le chargement des données si un changement de filtre est opéré avant la fin du chargement
  public subscription: any;
  // Gestion du spinner 
  public spinner = true;

  // Récupérer la liste des taxons existants dans la BDD pour permettre la recherche de taxon (pnx-taxonomy)
  public taxonApiEndPoint = `${AppConfig.API_ENDPOINT}/synthese/taxons_autocomplete`;

  constructor(
    public dataService: DataService,
    public fb: FormBuilder,
    public mapService: MapService
  ) {
    // Déclaration du formulaire général contenant les filtres de la carte
    this.mapForm = fb.group({
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

    //// Initialisation des variables formant la légende
    // Légende concernant le nombre d'observations
    this.divLegendObs = L.DomUtil.create("div", "divLegend");
    this.divLegendObs.innerHTML += "<b>Nombre d'observations</b><br/>";
    var nb_classes = this.gradesObs.length;
    for (var i = 0; i < nb_classes; i++) {
      this.divLegendObs.innerHTML +=
        '<i style="background:' +
        this.getColorObs(this.gradesObs[i]) +
        '"></i>' +
        this.gradesObs[i] +
        (this.gradesObs[i + 1]
          ? "&ndash;" + (this.gradesObs[i + 1] - 1) + "<br>"
          : "+");
    }
    // Légende concernant le nombre de taxons
    this.divLegendTax = L.DomUtil.create("div", "divLegend");
    this.divLegendTax.innerHTML += "<b>Nombre de taxons</b><br/>";
    var nb_classes = this.gradesTax.length;
    for (var i = 0; i < nb_classes; i++) {
      this.divLegendTax.innerHTML +=
        '<i style="background:' +
        this.getColorTax(this.gradesTax[i]) +
        '"></i>' +
        this.gradesTax[i] +
        (this.gradesTax[i + 1]
          ? "&ndash;" + (this.gradesTax[i + 1] - 1) + "<br>"
          : "+");
    }
  }

  ngOnInit() {
    // Accès aux données de synthèse
    this.subscription = this.dataService
      .getDataAreas(this.simplifyLevel, this.currentTypeCode)
      .subscribe(data => {
        // Initialisation du tableau contenant la géométrie et les données des zonages : par défaut, la carte s'affiche automatiquement en mode "communes"
        this.myAreas = data;
        this.spinner = false;
      });
    // Initialisation de la fonction "showData" : par défaut, la carte affiche automatiquement le nombre d'observations
    this.showData = this.onEachFeatureNbObs;
    // Récupération des noms de type_area qui seront contenus dans la liste déroulante du formulaire areaTypeControl
    this.dataService.getAreasTypes(ModuleConfig.AREA_TYPE).subscribe(data => {
      // Création de la liste déroulante
      this.tabAreasTypes = data;
    });
    // Abonnement à la liste déroulante du formulaire areaTypeControl afin de modifier le type de zonage à chaque changement
    this.areaTypeControl.valueChanges
      .distinctUntilChanged() // le [disableControl] du HTML déclenche l'API sans fin
      .skip(1) // l'initialisation de la liste déroulante sur "Communes" lance l'API une fois
      .subscribe(value => {
        this.spinner = true;
        this.currentTypeCode = value;
        // Accès aux données de synthèse
        this.dataService
          .getDataAreas(this.simplifyLevel, this.currentTypeCode, this.mapForm.value)
          .subscribe(data => {
            // Rafraichissement du tableau contenant la géométrie et les données des zonages
            this.myAreas = data;
            this.spinner = false;
          });
      });
  }

  ngOnChanges(change) {
    // Récupération des années min et max présentes dans la synthèse de GeoNature
    if (change.yearsMinMax && change.yearsMinMax.currentValue != undefined) {
      this.yearRange = change.yearsMinMax.currentValue;
    }
  }

  ngAfterViewInit() {
    // Implémentation de la légende : par défaut, la carte affiche automatiquement le nombre d'observations
    this.legend = (L as any).control({ position: "bottomright" });
    this.legend.onAdd = map => {
      return this.divLegendObs;
    };
    this.legend.addTo(this.mapService.map);
  }

  // Afficher les données, configurations (couleurs) et légende relatives au nombre de taxons (switcher)
  changeMapToTax() {
    this.myAreas = Object.assign({}, this.myAreas);
    this.showData = this.onEachFeatureNbTax.bind(this);
    this.mapService.map.removeControl(this.legend);
    this.legend.onAdd = map => {
      return this.divLegendTax;
    };
    this.legend.addTo(this.mapService.map);
    this.currentMap = 2; // Permet d'afficher les informations de légende associées au nombre de taxons
  }

  // Afficher les données, configurations (couleurs) et légende relatives au nombre d'observations (switcher)
  changeMapToObs() {
    this.myAreas = Object.assign({}, this.myAreas);
    this.showData = this.onEachFeatureNbObs.bind(this);
    this.mapService.map.removeControl(this.legend);
    this.legend.onAdd = map => {
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
    // Afficher les données d'origine si la valeur vaut ""
    if (this.filter == "") {
      // Accès aux données de synthèse
      this.dataService
        .getDataAreas(this.simplifyLevel, this.currentTypeCode, this.mapForm.value)
        .subscribe(data => {
          // Rafraichissement du tableau contenant la géométrie et les données des zonages
          this.myAreas = data;
        });
    }
  }
  getCurrentParameters(event) {
    this.subscription.unsubscribe();
    this.spinner = true;
    this.disabledTaxButton = false;
    // Copie des éléments du formulaire pour pouvoir y ajouter cd_ref s'il s'agit d'un filtre par taxon
    this.filtersDict = Object.assign({}, this.mapForm.value);
    // S'il s'agit d'une recherche de taxon...
    if (this.filter == "Rechercher un taxon/une espèce...") {
      // Cas d'une nouvelle recherche de taxon
      if (event.item) {
        // Récupération du cd_ref
        var cd_ref = event.item.cd_ref;
        // Enregistrement du cd_ref pour un potentiel changement de période concernant un taxon
        this.currentCdRef = cd_ref;
        // L'affichage de la carte du nombre de taxons n'a pas de sens lorsqu'on a sélectionné un taxon en particulier
        this.changeMapToObs();
      }
      // Cas d'un changement de la période sur le slider
      else {
        // Récupération du cd_ref
        var cd_ref = this.currentCdRef;
      }
      // Ajout de cd_ref à la liste des paramètres de la requête
      this.filtersDict["taxon"] = cd_ref;
      // Impossibilité d'afficher la carte en mode "Nombre de taxons"
      this.disabledTaxButton = true;
    }
    // Accès aux données de synthèse
    this.subscription = this.dataService
      .getDataAreas(this.simplifyLevel, this.currentTypeCode, this.filtersDict)
      .subscribe(data => {
        // Rafraichissement du tableau contenant la géométrie et les données des zonages
        this.myAreas = data;
        this.spinner = false;
      });
  }

  // Configuration de la carte relative au nombre d'observations
  onEachFeatureNbObs(feature, layer) {
    layer.setStyle({
      fillColor: this.getColorObs(feature.properties.nb_obs),
      color: this.initialBorderColor,
      fillOpacity: 0.9,
      weight: 1
    });
    layer.on({
      mouseover: this.highlightFeature.bind(this),
      mouseout: this.resetHighlight.bind(this),
      click: this.zoomToFeature.bind(this)
    });
  }

  // Configuration de la carte relative au nombre de taxons
  onEachFeatureNbTax(feature, layer) {
    layer.setStyle({
      fillColor: this.getColorTax(feature.properties.nb_taxons),
      color: this.initialBorderColor,
      fillOpacity: 0.9,
      weight: 1
    });
    layer.on({
      mouseover: this.highlightFeature.bind(this),
      mouseout: this.resetHighlight.bind(this),
      click: this.zoomToFeature.bind(this)
    });
  }

  // Couleurs de la carte relative au nombre d'observations
  getColorObs(obs) {
    var nb_classes = this.gradesObs.length;
    for (var i = 1; i < nb_classes; i++) {
      if (obs < this.gradesObs[i]) {
        return this.obsColors[nb_classes][i - 1];
      }
    }
    return this.obsColors[nb_classes][nb_classes - 1];
  }

  // Couleurs de la carte relative au nombre de taxons
  getColorTax(tax) {
    var nb_classes = this.gradesTax.length;
    for (var i = 1; i < nb_classes; i++) {
      if (tax < this.gradesTax[i]) {
        return this.taxColors[nb_classes][i - 1];
      }
    }
    return this.taxColors[nb_classes][nb_classes - 1];
  }

  // Changer l'aspect du zonage lorsque la souris passe dessus
  highlightFeature(e) {
    const layer = e.target;
    layer.setStyle({
      color: this.selectedBorderColor,
      weight: 5,
      fillOpacity: 1
    });
    layer.bringToFront();
    this.introLegend = null;
    this.currentArea = layer.feature.geometry.properties.area_name;
    if (this.currentMap == 1) {
      this.currentNbObs =
        "Nombre d'observations : " + layer.feature.geometry.properties.nb_obs;
    } else if (this.currentMap == 2) {
      this.currentNbTax =
        "Nombre de taxons : " + layer.feature.geometry.properties.nb_taxons;
    }
  }

  // Réinitialiser l'aspect du zonage lorsque la souris n'est plus dessus
  resetHighlight(e) {
    const layer = e.target;
    this.introLegend = "Placez la souris sur un zonage";
    this.currentArea = null;
    this.currentNbObs = null;
    this.currentNbTax = null;
    layer.setStyle({
      color: this.initialBorderColor,
      weight: 1,
      fillOpacity: 0.9
    });
  }

  // Zoomer sur un zonage en cliquant dessus
  zoomToFeature(e) {
    this.mapService.map.fitBounds(e.target.getBounds());
  }
}
