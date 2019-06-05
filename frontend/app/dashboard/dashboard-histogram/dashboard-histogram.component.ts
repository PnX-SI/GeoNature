import { Component, OnInit, ViewChild, Input } from "@angular/core";
import { FormBuilder, FormGroup } from "@angular/forms";
import { BaseChartDirective } from 'ng2-charts/ng2-charts';
// Services
import { DataService } from "../services/data.services";

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
  // public barChartOptions: any;
  public barChartLabels = [];
  public barChartType = 'bar';
  public barChartLegend = true;
  public barChartData = [ 
    {data: [], label: "Nombre d'observations", yAxisID: 'yAxisObs'}, 
    {data: [], label: "Nombre de taxons", yAxisID: 'yAxisTax'} 
  ];
  //public barChartData = [ {data: [], label: "Nombre d'observations"} ];
  public barChartColors = [ 
    {backgroundColor: 'rgba(159, 5, 63, 0.8)'}, 
    {backgroundColor: 'rgba(0, 128, 128, 0.8)'}
  ];
  //public barChartColors = [ {backgroundColor: 'rgba(159, 5, 63, 0.8)'} ];

  histForm: FormGroup;
  public filter: any;
  @Input() taxonomies: any;

  constructor(public dataService: DataService, public fb: FormBuilder) {
    // Déclaration du formulaire contenant les filtres de l'histogramme
    this.histForm = fb.group({
      selectedFilter: fb.control(null),
      selectedRegne: fb.control(null),
      selectedPhylum: fb.control(null),
      selectedClasse: fb.control(null),
      selectedOrdre: fb.control(null),
      selectedFamille: fb.control(null),
      selectedGroup1INPN: fb.control(null),
      selectedGroup2INPN: fb.control(null)
    });
  }

  ngOnInit() {
    // Implémentation du label de l'axe y
    //this.barChartOptions = this.createScaleLabel("Nombre d'observations");
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
      }
    );
  }

  // Rafraichissement des données en fonction des filtres renseignés par l'utilisateur
  refreshData() {
    console.log(this.histForm.value);
    // Réinitialisation de l'array des données à afficher, paramètre du bar chart
    this.barChartData = [ 
      {data: [], label: "Nombre d'observations", yAxisID: 'yAxisObs'}, 
      {data: [], label: "Nombre de taxons", yAxisID: 'yAxisTax'} 
    ];
    // Accès aux données de synthèse de la BDD GeoNature 
    this.dataService.getDataSynthese(this.histForm.value).subscribe(
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
                this.barChartData[0]["data"].push(data[i][1]);
                this.barChartData[1]["data"].push(data[i][2]);
                keepGoing = false;
                start = i+1;
              }
              i += 1;
            }
            if (keepGoing == true) {
              this.barChartData[0]["data"].push(0);
              this.barChartData[1]["data"].push(0);
            }
          }
        );
        this.chart.chart.update();
      }
    );
  }
  onTaxFilterChange(event){
    // Déterminer le type de filtre taxonomique qui a été sélectionné pour afficher la liste déroulante adéquate
    this.filter = event.target.value;
    // Réinitialiser l'ancien filtre qui a été sélectionné pour empêcher les erreurs de requête
    this.histForm.controls['selectedRegne'].reset();
    this.histForm.controls['selectedPhylum'].reset();
    this.histForm.controls['selectedClasse'].reset();
    this.histForm.controls['selectedOrdre'].reset();
    this.histForm.controls['selectedFamille'].reset();
    this.histForm.controls['selectedGroup1INPN'].reset();
    this.histForm.controls['selectedGroup2INPN'].reset();
    console.log(this.histForm.value);
  }

  // // Afficher les données relatives au nombre de taxons
  // changeHistToTax() {  
  //   this.barChartData = [ {data: [], label: "Nombre de taxons"} ];
  //   this.barChartOptions = this.createScaleLabel("Nombre de taxons");
  //   // Accès aux données de la BDD GeoNature 
  //   this.dataService.getDataSynthese().subscribe(
  //     (data) => {
  //       // Création des variables qui seront paramètres du bar chart
  //       data.forEach(
  //         (elt) => {
  //           this.barChartData[0]["data"].push(elt[2]);
  //         }
  //       );
  //       this.barChartColors = [ {backgroundColor: 'rgba(0, 128, 128, 0.8)'} ];
  //     }
  //   );
  // }

  // // Afficher les données relatives au nombre d'observations
  // changeHistToObs() {   
  //   this.barChartData = [ {data: [], label: "Nombre d'observations'"} ];
  //   this.barChartOptions = this.createScaleLabel("Nombre d'observations");
  //   // Accès aux données de la BDD GeoNature 
  //   this.dataService.getDataSynthese().subscribe(
  //     (data) => {
  //       // Création des variables qui seront paramètres du bar chart
  //       data.forEach(
  //         (elt) => {
  //           this.barChartData[0]["data"].push(elt[1]);
  //         }
  //       );
  //       this.barChartColors = [ {backgroundColor: 'rgba(159, 5, 63, 0.8)'} ];
  //     }
  //   );
  // }

  // // Créer le label de l'axe y
  // createScaleLabel(label) {   
  //   const options = {
  //     scaleShowVerticalLines: true,
  //     responsive: true,
  //     tooltips: {
  //       mode: "index",
  //       intersect: true
  //     },
  //     scales: {
  //       yAxes: [
  //         {
  //           position: "left",
  //           ticks: {
  //             beginAtZero: true
  //           },
  //           scaleLabel: {
  //             display: true,
  //             labelString: label,
  //             fontColor: 'rgb(159, 5, 63)'
  //           }
  //         }
  //       ]
  //     }
  //   };
  //   return options;
  // }

}
