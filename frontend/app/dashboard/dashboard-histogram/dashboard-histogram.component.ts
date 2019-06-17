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
            fontColor: 'rgb(159, 5, 63)'
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
            fontColor: 'rgb(0, 128, 128)'
          }
        }
      ]
    }
  };
  public barChartLabels = [];
  public noFilterBarChartLabels = [];
  public barChartType = 'bar';
  public barChartLegend = true;
  public barChartData = [ 
    {data: [], label: "Nombre d'observations", yAxisID: 'yAxisObs'}, 
    {data: [], label: "Nombre de taxons", yAxisID: 'yAxisTax'} 
  ];
  public noFilterBarChartData = [];
  public barChartColors = [ 
    {backgroundColor: 'rgba(159, 5, 63, 0.8)'}, 
    {backgroundColor: 'rgba(0, 128, 128, 0.8)'}
  ];

  histForm: FormGroup;
  public filter: any;
  @Input() taxonomies: any;

  public filtersDict: { [filter: string]: any } = { };

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
    // Accès aux données de synthèse de la BDD GeoNature 
    this.dataService.getDataSynthese().subscribe(
      (data) => {
        // console.log(data);
        // Remplissage des array qui seront paramètres du bar chart
        data.forEach(
          (elt) => {
            this.barChartLabels.push(elt[0]);
            this.barChartData[0]["data"].push(elt[1]);
            this.barChartData[1]["data"].push(elt[2]);
          }
        );
        this.chart.chart.update();
        this.noFilterBarChartLabels = this.barChartLabels;
        this.noFilterBarChartData = this.barChartData;
      }
    );
  }

  // Rafraichissement des données en fonction des filtres renseignés par l'utilisateur
  onTaxFilterChange(event){
    // Déterminer le type de filtre taxonomique qui a été sélectionné pour afficher la liste déroulante adéquate
    this.filter = event.target.value;
    // Réinitialiser l'ancien filtre qui a été sélectionné pour empêcher les erreurs de requête
    for (var key in this.filtersDict) {
      delete this.filtersDict[key];
    }
    this.histForm.controls['selectedGroup1INPN'].reset();
    this.histForm.controls['selectedGroup2INPN'].reset();
    this.histForm.controls['selectedRegne'].reset();
    this.histForm.controls['selectedPhylum'].reset();
    this.histForm.controls['selectedClasse'].reset();
    this.histForm.controls['selectedOrdre'].reset();
    this.histForm.controls['selectedFamille'].reset();
    // console.log(this.filtersDict);
    // console.log(this.histForm.value);
    if (this.filter == "") {
      this.barChartData = this.noFilterBarChartData;
    }
  }
  getCurrentGroup1INPN(event){
    console.log(event);
    var index = event.target.value.indexOf(':');
    this.filtersDict["selectedGroup1INPN"] = event.target.value.substring(index+2,);
    console.log(this.filtersDict);
    // Si le filtre Groupe INPN 1 est sur "", on affiche les données d'origine
    if (this.filtersDict["selectedGroup1INPN"] == "") {
      this.barChartData = this.noFilterBarChartData;
    }
    // Sinon, on charge les nouvelles données correspondant à la requête
    else {
      // Réinitialisation de l'array des données à afficher, paramètre du bar chart
      var barChartDataTemp = [ 
        {data: [], label: "Nombre d'observations", yAxisID: 'yAxisObs'}, 
        {data: [], label: "Nombre de taxons", yAxisID: 'yAxisTax'} 
      ];
      // Accès aux données de synthèse de la BDD GeoNature 
      this.dataService.getDataSynthese(this.filtersDict).subscribe(
        (data) => {
          console.log(data);
          // Remplissage de l'array en tenant compte du fait qu'il ne peut y avoir aucune observation pour certaines années 
          const dataLength = data.length;
          var start = 0;
          this.barChartLabels.forEach(
            (year) => {
              var i = start;
              var keepGoing = true;
              while ((i < dataLength) && (keepGoing == true)) {
                if (year == data[i][0]) {
                  barChartDataTemp[0]["data"].push(data[i][1]);
                  barChartDataTemp[1]["data"].push(data[i][2]);
                  keepGoing = false;
                  start = i+1;
                }
                i += 1;
              }
              if (keepGoing == true) {
                barChartDataTemp[0]["data"].push(0);
                barChartDataTemp[1]["data"].push(0);
              }
            }
          );
          this.barChartData = barChartDataTemp;
        }
      );
    }
  }
  getCurrentGroup2INPN(event){
    console.log(event);
    var index = event.target.value.indexOf(':');
    this.filtersDict["selectedGroup2INPN"] = event.target.value.substring(index+2,);
    console.log(this.filtersDict);
    // Si le filtre Groupe INPN 2 est sur "", on affiche les données d'origine
    if (this.filtersDict["selectedGroup2INPN"] == "") {
      this.barChartData = this.noFilterBarChartData;
    }
    // Sinon, on charge les nouvelles données correspondant à la requête
    else {
      // Réinitialisation de l'array des données à afficher, paramètre du bar chart
      var barChartDataTemp = [ 
        {data: [], label: "Nombre d'observations", yAxisID: 'yAxisObs'}, 
        {data: [], label: "Nombre de taxons", yAxisID: 'yAxisTax'} 
      ];
      // Accès aux données de synthèse de la BDD GeoNature 
      this.dataService.getDataSynthese(this.filtersDict).subscribe(
        (data) => {
          console.log(data);
          // Remplissage de l'array en tenant compte du fait qu'il ne peut y avoir aucune observation pour certaines années 
          const dataLength = data.length;
          var start = 0;
          this.barChartLabels.forEach(
            (year) => {
              var i = start;
              var keepGoing = true;
              while ((i < dataLength) && (keepGoing == true)) {
                if (year == data[i][0]) {
                  barChartDataTemp[0]["data"].push(data[i][1]);
                  barChartDataTemp[1]["data"].push(data[i][2]);
                  keepGoing = false;
                  start = i+1;
                }
                i += 1;
              }
              if (keepGoing == true) {
                barChartDataTemp[0]["data"].push(0);
                barChartDataTemp[1]["data"].push(0);
              }
            }
          );
          this.barChartData = barChartDataTemp;
        }
      );
    }
  }
  getCurrentRegne(event){
    var index = event.target.value.indexOf(':');
    this.filtersDict["selectedRegne"] = event.target.value.substring(index+2,);
    console.log(this.filtersDict);
    // Si le filtre Règne est sur "", on affiche les données d'origine
    if (this.filtersDict["selectedRegne"] == "") {
      this.barChartData = this.noFilterBarChartData;
    }
    // Sinon, on charge les nouvelles données correspondant à la requête
    else {
      // Réinitialisation de l'array des données à afficher, paramètre du bar chart
      var barChartDataTemp = [ 
        {data: [], label: "Nombre d'observations", yAxisID: 'yAxisObs'}, 
        {data: [], label: "Nombre de taxons", yAxisID: 'yAxisTax'} 
      ];
      // Accès aux données de synthèse de la BDD GeoNature 
      this.dataService.getDataSynthese(this.filtersDict).subscribe(
        (data) => {
          console.log(data);
          // Remplissage de l'array en tenant compte du fait qu'il ne peut y avoir aucune observation pour certaines années 
          const dataLength = data.length;
          var start = 0;
          this.barChartLabels.forEach(
            (year) => {
              var i = start;
              var keepGoing = true;
              while ((i < dataLength) && (keepGoing == true)) {
                if (year == data[i][0]) {
                  barChartDataTemp[0]["data"].push(data[i][1]);
                  barChartDataTemp[1]["data"].push(data[i][2]);
                  keepGoing = false;
                  start = i+1;
                }
                i += 1;
              }
              if (keepGoing == true) {
                barChartDataTemp[0]["data"].push(0);
                barChartDataTemp[1]["data"].push(0);
              }
            }
          );
          this.barChartData = barChartDataTemp;
        }
      );
    }
  }
  getCurrentPhylum(event){
    var index = event.target.value.indexOf(':');
    this.filtersDict["selectedPhylum"] = event.target.value.substring(index+2,);
    console.log(this.filtersDict);
    // Si le filtre Phylum est sur "", on affiche les données d'origine
    if (this.filtersDict["selectedPhylum"] == "") {
      this.barChartData = this.noFilterBarChartData;
    }
    // Sinon, on charge les nouvelles données correspondant à la requête
    else {
      // Réinitialisation de l'array des données à afficher, paramètre du bar chart
      var barChartDataTemp = [ 
        {data: [], label: "Nombre d'observations", yAxisID: 'yAxisObs'}, 
        {data: [], label: "Nombre de taxons", yAxisID: 'yAxisTax'} 
      ];
      // Accès aux données de synthèse de la BDD GeoNature 
      this.dataService.getDataSynthese(this.filtersDict).subscribe(
        (data) => {
          console.log(data);
          // Remplissage de l'array en tenant compte du fait qu'il ne peut y avoir aucune observation pour certaines années 
          const dataLength = data.length;
          var start = 0;
          this.barChartLabels.forEach(
            (year) => {
              var i = start;
              var keepGoing = true;
              while ((i < dataLength) && (keepGoing == true)) {
                if (year == data[i][0]) {
                  barChartDataTemp[0]["data"].push(data[i][1]);
                  barChartDataTemp[1]["data"].push(data[i][2]);
                  keepGoing = false;
                  start = i+1;
                }
                i += 1;
              }
              if (keepGoing == true) {
                barChartDataTemp[0]["data"].push(0);
                barChartDataTemp[1]["data"].push(0);
              }
            }
          );
          this.barChartData = barChartDataTemp;
        }
      );
    }
  }
  getCurrentClasse(event){
    var index = event.target.value.indexOf(':');
    this.filtersDict["selectedClasse"] = event.target.value.substring(index+2,);
    console.log(this.filtersDict);
    // Si le filtre Classe est sur "", on affiche les données d'origine
    if (this.filtersDict["selectedClasse"] == "") {
      this.barChartData = this.noFilterBarChartData;
    }
    // Sinon, on charge les nouvelles données correspondant à la requête
    else {
      // Réinitialisation de l'array des données à afficher, paramètre du bar chart
      var barChartDataTemp = [ 
        {data: [], label: "Nombre d'observations", yAxisID: 'yAxisObs'}, 
        {data: [], label: "Nombre de taxons", yAxisID: 'yAxisTax'} 
      ];
      // Accès aux données de synthèse de la BDD GeoNature 
      this.dataService.getDataSynthese(this.filtersDict).subscribe(
        (data) => {
          console.log(data);
          // Remplissage de l'array en tenant compte du fait qu'il ne peut y avoir aucune observation pour certaines années 
          const dataLength = data.length;
          var start = 0;
          this.barChartLabels.forEach(
            (year) => {
              var i = start;
              var keepGoing = true;
              while ((i < dataLength) && (keepGoing == true)) {
                if (year == data[i][0]) {
                  barChartDataTemp[0]["data"].push(data[i][1]);
                  barChartDataTemp[1]["data"].push(data[i][2]);
                  keepGoing = false;
                  start = i+1;
                }
                i += 1;
              }
              if (keepGoing == true) {
                barChartDataTemp[0]["data"].push(0);
                barChartDataTemp[1]["data"].push(0);
              }
            }
          );
          this.barChartData = barChartDataTemp;
        }
      );
    }
  }
  getCurrentOrdre(event){
    var index = event.target.value.indexOf(':');
    this.filtersDict["selectedOrdre"] = event.target.value.substring(index+2,);
    console.log(this.filtersDict);
    // Si le filtre Ordre est sur "", on affiche les données d'origine
    if (this.filtersDict["selectedOrdre"] == "") {
      this.barChartData = this.noFilterBarChartData;
    }
    // Sinon, on charge les nouvelles données correspondant à la requête
    else {
      // Réinitialisation de l'array des données à afficher, paramètre du bar chart
      var barChartDataTemp = [ 
        {data: [], label: "Nombre d'observations", yAxisID: 'yAxisObs'}, 
        {data: [], label: "Nombre de taxons", yAxisID: 'yAxisTax'} 
      ];
      // Accès aux données de synthèse de la BDD GeoNature 
      this.dataService.getDataSynthese(this.filtersDict).subscribe(
        (data) => {
          console.log(data);
          // Remplissage de l'array en tenant compte du fait qu'il ne peut y avoir aucune observation pour certaines années 
          const dataLength = data.length;
          var start = 0;
          this.barChartLabels.forEach(
            (year) => {
              var i = start;
              var keepGoing = true;
              while ((i < dataLength) && (keepGoing == true)) {
                if (year == data[i][0]) {
                  barChartDataTemp[0]["data"].push(data[i][1]);
                  barChartDataTemp[1]["data"].push(data[i][2]);
                  keepGoing = false;
                  start = i+1;
                }
                i += 1;
              }
              if (keepGoing == true) {
                barChartDataTemp[0]["data"].push(0);
                barChartDataTemp[1]["data"].push(0);
              }
            }
          );
          this.barChartData = barChartDataTemp;
        }
      );
    }
  }
  getCurrentFamille(event){
    var index = event.target.value.indexOf(':');
    this.filtersDict["selectedFamille"] = event.target.value.substring(index+2,);
    console.log(this.filtersDict);
    // Si le filtre Famille est sur "", on affiche les données d'origine
    if (this.filtersDict["selectedFamille"] == "") {
      this.barChartData = this.noFilterBarChartData;
    }
    // Sinon, on charge les nouvelles données correspondant à la requête
    else {
      // Réinitialisation de l'array des données à afficher, paramètre du bar chart
      var barChartDataTemp = [ 
        {data: [], label: "Nombre d'observations", yAxisID: 'yAxisObs'}, 
        {data: [], label: "Nombre de taxons", yAxisID: 'yAxisTax'} 
      ];
      // Accès aux données de synthèse de la BDD GeoNature 
      this.dataService.getDataSynthese(this.filtersDict).subscribe(
        (data) => {
          console.log(data);
          // Remplissage de l'array en tenant compte du fait qu'il ne peut y avoir aucune observation pour certaines années 
          const dataLength = data.length;
          var start = 0;
          this.barChartLabels.forEach(
            (year) => {
              var i = start;
              var keepGoing = true;
              while ((i < dataLength) && (keepGoing == true)) {
                if (year == data[i][0]) {
                  barChartDataTemp[0]["data"].push(data[i][1]);
                  barChartDataTemp[1]["data"].push(data[i][2]);
                  keepGoing = false;
                  start = i+1;
                }
                i += 1;
              }
              if (keepGoing == true) {
                barChartDataTemp[0]["data"].push(0);
                barChartDataTemp[1]["data"].push(0);
              }
            }
          );
          this.barChartData = barChartDataTemp;
        }
      );
    }
  }
  getCurrentTaxon(event){
    console.log(event.item.cd_ref);
    this.filtersDict["selectedTaxon"] = event.item.cd_ref;
    console.log(this.filtersDict);
    // Si le filtre Famille est sur "", on affiche les données d'origine
    if (this.filtersDict["selectedTaxon"] == "") {
      this.barChartData = this.noFilterBarChartData;
    }
    // Sinon, on charge les nouvelles données correspondant à la requête
    else {
      // Réinitialisation de l'array des données à afficher, paramètre du bar chart
      var barChartDataTemp = [ 
        {data: [], label: "Nombre d'observations", yAxisID: 'yAxisObs'}, 
        {data: [], label: "Nombre de taxons", yAxisID: 'yAxisTax'} 
      ];
      // Accès aux données de synthèse de la BDD GeoNature 
      this.dataService.getDataSynthese(this.filtersDict).subscribe(
        (data) => {
          console.log(data);
          // Remplissage de l'array en tenant compte du fait qu'il ne peut y avoir aucune observation pour certaines années 
          const dataLength = data.length;
          var start = 0;
          this.barChartLabels.forEach(
            (year) => {
              var i = start;
              var keepGoing = true;
              while ((i < dataLength) && (keepGoing == true)) {
                if (year == data[i][0]) {
                  barChartDataTemp[0]["data"].push(data[i][1]);
                  barChartDataTemp[1]["data"].push(data[i][2]);
                  keepGoing = false;
                  start = i+1;
                }
                i += 1;
              }
              if (keepGoing == true) {
                barChartDataTemp[0]["data"].push(0);
                barChartDataTemp[1]["data"].push(0);
              }
            }
          );
          this.barChartData = barChartDataTemp;
          console.log(this.barChartData);
        }, (error) => {
          console.log(error); 
          this.commonService.toastrService.info("Il n'y a aucune donnée disponible pour ce taxon","");        
        }
      );
    }
  }

}
