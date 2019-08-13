import { Component, OnInit, ViewChild, Input } from "@angular/core";
import { FormBuilder, FormGroup } from "@angular/forms";
import { BaseChartDirective } from 'ng2-charts/ng2-charts';
// Services
import { DataService } from "../services/data.services";

@Component({
  selector: "dashboard-species",
  templateUrl: "dashboard-species.component.html",
  styleUrls: ['./dashboard-species.component.scss']
})

export class DashboardSpeciesComponent implements OnInit {

  @ViewChild(BaseChartDirective) chart: BaseChartDirective;

  public subscription: any;
  // Type de graphe
  public pieChartType = 'doughnut';
  // Tableau contenant les labels du graphe
  public pieChartLabels = ["Taxons recontactés", "Taxons non recontactés", "Nouveaux taxons"];
  // Tableau contenant les données du graphe
  public pieChartData = [];
  // Dictionnaire contenant les couleurs et la taille de bordure du graphe
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

  speciesForm: FormGroup;
  @Input() distinctYears: any;
  public spinner = false;

  constructor(public dataService: DataService, public fb: FormBuilder) {
    // Déclaration du formulaire contenant les filtres du pie chart
    this.speciesForm = fb.group({
      selectedYear: fb.control(null)
    });
  }

  ngOnInit() {
    this.spinner = true;
    // Par défaut, le pie chart s'affiche à l'année en court
    this.speciesForm.controls["selectedYear"].setValue(this.distinctYears[this.distinctYears.length - 1]);
    // Accès aux données de synthèse de la BDD GeoNature
    this.subscription = this.dataService.getSpecies({ selectedYear: this.speciesForm.value.selectedYear }).subscribe(
      (data) => {
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
    // Accès aux données de synthèse de la BDD GeoNature
    this.subscription = this.dataService.getSpecies({ selectedYear: this.speciesForm.value.selectedYear }).subscribe(
      (data) => {
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
