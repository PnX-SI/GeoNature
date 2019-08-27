import { Component, OnInit, ViewChild, Input } from "@angular/core";
import { FormBuilder, FormGroup } from "@angular/forms";
import { BaseChartDirective } from 'ng2-charts/ng2-charts';
import { AppConfig } from '@geonature_config/app.config';
// Services
import { DataService } from "../services/data.services";
import { CommonService } from "@geonature_common/service/common.service";

@Component({
  selector: "dashboard-histogram",
  templateUrl: "dashboard-histogram.component.html",
  styleUrls: ['./dashboard-histogram.component.scss']
})

export class DashboardHistogramComponent implements OnInit {

  @ViewChild(BaseChartDirective) chart: BaseChartDirective;

  // Type de graphe
  public barChartType = 'bar';
  // Tableau contenant les labels du graphe
  public barChartLabels = [];
  // Tableau contenant les données du graphe
  public barChartData = [
    { data: [], label: "Nombre d'observations", yAxisID: 'yAxisObs' },
    { data: [], label: "Nombre de taxons", yAxisID: 'yAxisTax' }
  ];
  // Pouvoir enregistrer le tableau des données au chargement du composant lorsqu'aucun filtre n'est sélectionné (accélérer l'affichage des données par la suite)
  public noFilterBarChartData = [];
  // Tableau contenant les couleurs du graphe
  public barChartColors = [
    { backgroundColor: 'rgba(159, 5, 63, 0.8)' },
    { backgroundColor: 'rgba(0, 128, 128, 0.8)' }
  ];
  // Dictionnaire contenant les options à implémenter sur le graphe (affichage des deux axes avec leur légende notamment) 
  public barChartOptions = {
    scaleShowVerticalLines: true,
    responsive: true,
    tooltips: {
      mode: "index",
      intersect: true
    },
    plugins: {
      labels: []
    },
    scales: {
      xAxes: [{
        display: true,
        scaleLabel: {
          display: true,
          labelString: 'Années',
          fontSize: 16
        }
      }],
      yAxes: [
        {
          id: "yAxisObs",
          position: "left",
          stacked: true,
          ticks: {
            beginAtZero: true,
            fontColor: 'rgb(159, 5, 63)'
          },
          scaleLabel: {
            display: true,
            labelString: "Nombre d'observations",
            fontColor: 'rgb(159, 5, 63)',
            fontSize: 16
          }
        },
        {
          id: "yAxisTax",
          position: "right",
          stacked: true,
          ticks: {
            beginAtZero: true,
            fontColor: 'rgb(0, 128, 128)'
          },
          gridLines: {
            drawOnChartArea: false
          },
          scaleLabel: {
            display: true,
            labelString: "Nombre de taxons",
            fontColor: 'rgb(0, 128, 128)',
            fontSize: 16
          }
        }
      ]
    }
  };

  // Gestion du formulaire
  histForm: FormGroup;
  @Input() taxonomies: any;
  public filter: any;
  public currentTaxon = "";

  // Pouvoir stoppper le chargement des données si un changement de filtre est opéré avant la fin du chargement
  public subscription: any;
  // Gestion du spinner
  public spinner = true;

  // Récupérer la liste des taxons existants dans la BDD pour permettre la recherche de taxon (pnx-taxonomy)
  public taxonApiEndPoint = `${AppConfig.API_ENDPOINT}/synthese/taxons_autocomplete`;

  constructor(public dataService: DataService, public commonService: CommonService, public fb: FormBuilder) {
    // Déclaration du formulaire contenant les filtres de l'histogramme
    this.histForm = fb.group({
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
  }

  ngOnInit() {
    // Accès aux données de la VM vm_synthese
    this.subscription = this.dataService.getDataSynthese().subscribe(
      (data) => {
        // Remplissage des array des labels et des données à afficher, paramètres de l'histogramme
        data.forEach(
          (elt) => {
            this.barChartLabels.push(elt[0]);
            this.barChartData[0]["data"].push(elt[1]);
            this.barChartData[1]["data"].push(elt[2]);
          }
        );
        this.chart.chart.update();
        // Enregistrement des données "sans filtre" pour pouvoir les afficher plus rapidement par la suite
        this.noFilterBarChartData = this.barChartData;
        this.spinner = false;
      }
    );
  }

  // Rafraichissement des données en fonction des filtres renseignés par l'utilisateur
  onTaxFilterChange(event) {
    // Déterminer le type de filtre taxonomique qui a été sélectionné pour afficher la liste déroulante adéquate
    this.filter = event.target.value;
    // Réinitialiser l'ancien filtre qui a été sélectionné pour empêcher les erreurs de requête
    this.histForm.controls['selectedGroup1INPN'].reset();
    this.histForm.controls['selectedGroup2INPN'].reset();
    this.histForm.controls['selectedRegne'].reset();
    this.histForm.controls['selectedPhylum'].reset();
    this.histForm.controls['selectedClasse'].reset();
    this.histForm.controls['selectedOrdre'].reset();
    this.histForm.controls['selectedFamille'].reset();
    this.histForm.controls['taxon'].reset();
    // Afficher les données d'origine si la valeur vaut ""
    if (this.filter == "") {
      this.barChartData = this.noFilterBarChartData;
      this.currentTaxon = "";
    }
  }
  getCurrentTax(event) {
    this.subscription.unsubscribe();
    this.spinner = true;
    //// Actualiser le titre du graphe avec le nom du taxon sélectionné (currentTaxon)
    // Différents cas selon qu'il s'agit d'une recherche de taxon ou d'une liste déroulante
    if (this.filter == 'Rechercher un taxon/une espèce...') {
      var label = event.item.cd_ref;
      this.currentTaxon = event.item.lb_nom;
      // Récupération du cd_ref dans le formulaire
      this.histForm.controls['taxon'].setValue(label);
    }
    else {
      var index = event.target.value.indexOf(':');
      var label = event.target.value.substring(index + 2);
      this.currentTaxon = label;
    }
    //// Afficher les données d'origine si la valeur vaut ""
    if (label == "") {
      this.barChartData = this.noFilterBarChartData;
      this.spinner = false;
    }
    //// Sinon...
    else {
      // Réinitialisation de l'array des données à afficher, paramètre de l'histogramme
      var barChartDataTemp = [
        { data: [], label: "Nombre d'observations", yAxisID: 'yAxisObs' },
        { data: [], label: "Nombre de taxons", yAxisID: 'yAxisTax' }
      ];
      // Accès aux données de la VM vm_synthese 
      this.subscription = this.dataService.getDataSynthese(this.histForm.value).subscribe(
        (data) => {
          // Remplissage de l'array des données, en tenant compte du fait qu'il peut n'y avoir aucune observation pour certaines années 
          const dataLength = data.length;
          var start = 0;
          this.barChartLabels.forEach(
            (year) => {
              var i = start;
              var keepGoing = true;
              while ((i < dataLength) && (keepGoing == true)) {
                if (year == data[i][0]) {
                  barChartDataTemp[0]["data"].push(data[i][1]);
                  if (this.filter != 'Rechercher un taxon/une espèce...') {
                    barChartDataTemp[1]["data"].push(data[i][2]);
                  }
                  keepGoing = false;
                  start = i + 1;
                }
                i += 1;
              }
              if (keepGoing == true) {
                barChartDataTemp[0]["data"].push(0);
                if (this.filter != 'Rechercher un taxon/une espèce...') {
                  barChartDataTemp[1]["data"].push(0);
                }
              }
            }
          );
          this.barChartData = barChartDataTemp;
          this.spinner = false;
        }, (error) => {
          // Affichage d'un message d'erreur s'il n'y a pas de données pour le taxon sélectionné
          this.commonService.toastrService.info("Il n'y a aucune donnée disponible pour ce taxon", "");
        }
      );
    }
  }

}
