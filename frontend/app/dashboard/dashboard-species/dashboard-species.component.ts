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

  public pieChartType = 'doughnut';
  public pieChartLabels = ["Espèces recontactées", "Espèces non recontactées", "Nouvelles espèces"];
  public pieChartData = [];
  public pieChartColors = [
    {
      backgroundColor: ["rgb(119,163,53)", "rgb(217,146,30)", "rgb(43,132,183)"],
      borderWidth: 0.8
    }
  ];
  public pieChartOptions = {
    legend: {
      display: 'true',
      position: 'right',
      labels: {
        fontSize: 15,
        filter: function (legendItem, chartData) {
          return chartData.datasets[0].data[legendItem.index] != 0;
        }
      }
    },
    plugins: {
      // outlabels: {
      //   text: '%p',
      //   color: 'white',
      //   stretch: 45,
      //   font: {
      //     resizable: true,
      //     minSize: 12,
      //     maxSize: 18
      //   }
      // },
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
          // position: 'outside',
          // textMargin: 15,
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
    // Par défaut, le pie chart s'affiche au niveau du règne
    this.speciesForm.controls["selectedYear"].setValue(2019);
    // Accès aux données de synthèse de la BDD GeoNature
    this.dataService.getSpecies({ selectedYear: this.speciesForm.value.selectedYear }).subscribe(
      (data) => {
        // console.log(data);
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
    this.spinner = true;
    // Réinitialisation de l'array des données à afficher, paramètre du pie chart
    var pieChartDataTemp = [];
    // Accès aux données de synthèse de la BDD GeoNature
    this.dataService.getSpecies({ selectedYear: this.speciesForm.value.selectedYear }).subscribe(
      (data) => {
        data.forEach(
          (elt) => {
            pieChartDataTemp.push(elt);
          }
        )
        this.pieChartData = pieChartDataTemp;
        this.spinner = false;
        console.log(this.pieChartData);
      }
    );
  }

}
