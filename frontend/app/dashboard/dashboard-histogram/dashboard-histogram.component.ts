import { Component, OnInit, ViewChild } from "@angular/core";
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

  public myDataSynthese: Array<any>;
  public barChartOptions = {
    scaleShowVerticalLines: true,
    responsive: true,
    // title: {
    //   display: true,
    //   text: "Statistiques par année"
    // },
    tooltips: {
      mode: "index",
      intersect: true
    },
    scales: {
      yAxes: [
        {
          id: "yAxisObs",
          position: "left",
          ticks: {
            beginAtZero: true
          },
          scaleLabel: {
            display: true,
            labelString: "Nombre d'observations"
          }
        },
        {
          id: "yAxisTax",
          position: "right",
          ticks: {
            beginAtZero: true
          },
          gridLines: {
            drawOnChartArea: false
          },
          scaleLabel: {
            display: true,
            labelString: "Nombre de taxons"
          }
        }
      ]
    }
  };
  public barChartLabels = [];
  public barChartType = 'bar';
  public barChartLegend = true;
  public barChartData = [ 
    {data: [], label: "Nombre d'observations", yAxisID: 'yAxisObs'}, 
    {data: [], label: "Nombre de taxons", yAxisID: 'yAxisTax'} 
  ];
  public barChartColors = [ 
    {backgroundColor: 'rgba(159, 5, 63, 0.8)'}, 
    {backgroundColor: 'rgba(0, 128, 128, 0.8)'}
  ];

  constructor(public dataService: DataService) {}

  ngOnInit() {
    // Accès aux données de la BDD GeoNature 
    this.dataService.getDataSynthese().subscribe(
      (data) => {
        console.log(data);
        this.myDataSynthese=data;
        // Création des variables qui seront paramètres du bar chart
        this.myDataSynthese.forEach(
          (elt) => {
            this.barChartLabels.push(elt[0]);
            this.barChartData[0]["data"].push(elt[1]);
            this.barChartData[1]["data"].push(elt[2]);
          }
        );
        this.chart.chart.update();
      }
    );
    console.log(this.barChartLabels);
    console.log(this.barChartData[0]["data"]);
    console.log(this.barChartData[1]["data"]);
  }

}
