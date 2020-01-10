import { Component, OnInit, ViewChild, Input } from "@angular/core";
import { FormBuilder, FormGroup } from "@angular/forms";
import { BaseChartDirective } from 'ng2-charts';
// Services
import { DataService } from "../services/data.services";

@Component({
  selector: "dashboard-recontact",
  templateUrl: "dashboard-recontact.component.html",
  styleUrls: ['./dashboard-recontact.component.scss']
})

export class DashboardRecontactComponent implements OnInit {

  @ViewChild(BaseChartDirective) chart: BaseChartDirective;

  // Type de graphe
  public pieChartType = 'doughnut';
  // Tableau contenant les labels du graphe
  public pieChartLabels = ["Taxons recontactés", "Taxons non recontactés", "Nouveaux taxons"];
  // Tableau contenant les données du graphe
  public pieChartData = [];
  // Tableau contenant les couleurs et la taille de bordure du graphe
  public pieChartColors = [
    {
      backgroundColor: ["rgb(119,163,53)", "rgb(217,146,30)", "rgb(43,132,183)"],
      borderWidth: 0.8
    }
  ];
  // Dictionnaire contenant les options à implémenter sur le graphe (calcul des pourcentages notamment)
  public pieChartOptions = {
    legend: {
      display: 'true',
      position: 'left',
      labels: {
        fontSize: 15,
        filter: function (legendItem, chartData) {
          return chartData.datasets[0].data[legendItem.index] != 0;
        }
      }
    },
    plugins: {
      labels: [
        {
          render: 'label',
          arc: true,
          fontSize: 14,
          position: 'outside',
          overlap: false
        },
        {
          render: 'percentage',
          fontColor: 'white',
          fontSize: 14,
          fontStyle: 'bold',
          precision: 2,
          textShadow: true,
          overlap: false
        }
      ]
    }
  }

  // Gestion du formulaire
  recontactForm: FormGroup;
  @Input() distinctYears: any;

  // Pouvoir stoppper le chargement des données si un changement de filtre est opéré avant la fin du chargement
  public subscription: any;
  // Gestion du spinner
  public spinner = true;

  constructor(public dataService: DataService, public fb: FormBuilder) {
    // Déclaration du formulaire contenant les filtres du pie chart
    this.recontactForm = fb.group({
      selectedYear: fb.control(null)
    });
  }

  ngOnInit() {
    // Par défaut, le pie chart s'affiche sur l'année en court
    this.recontactForm.controls["selectedYear"].setValue(this.distinctYears[this.distinctYears.length - 1]);
    // Accès aux données de synthèse
    this.subscription = this.dataService.getDataRecontact(this.recontactForm.value.selectedYear).subscribe(
      (data) => {
        // Remplissage de l'array des données à afficher, paramètre du line chart
        data.forEach(
          (elt) => {
            this.pieChartData.push(elt);
          }
        )
        this.chart.chart.update();
        this.spinner = false;
      }
    );
  }

  // Rafraichissement des données en fonction de l'année renseignée par l'utilisateur
  getCurrentYear(event) {
    this.subscription.unsubscribe();
    this.spinner = true;
    // Réinitialisation de l'array des données à afficher, paramètre du pie chart
    var pieChartDataTemp = [];
    // Accès aux données de synthèse
    this.subscription = this.dataService.getDataRecontact(this.recontactForm.value.selectedYear).subscribe(
      (data) => {
        // Remplissage de l'array des données à afficher, paramètre du line chart
        data.forEach(
          (elt) => {
            pieChartDataTemp.push(elt);
          }
        )
        this.pieChartData = pieChartDataTemp;
        this.spinner = false;
      }
    );
  }

}
