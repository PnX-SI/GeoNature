import { Component, OnInit, ViewChild, Input } from "@angular/core";
import { FormBuilder, FormGroup } from "@angular/forms";
import { BaseChartDirective } from 'ng2-charts/ng2-charts';
// Services
import { DataService } from "../services/data.services";

@Component({
  selector: "dashboard-line-chart",
  templateUrl: "dashboard-line-chart.component.html",
  styleUrls: ['./dashboard-line-chart.component.scss']
})

export class DashboardLineChartComponent implements OnInit {

  @ViewChild(BaseChartDirective) chart: BaseChartDirective;

  public frameworksName = [];
  public nbFrameworks: any;
  public lineChartType = 'line';
  public lineChartLabels = [];
  public lineChartData = [];
  public colors = [
    {
      backgroundColor: "rgba(217,146,30, 0.7)",
      borderColor: "rgb(217,146,30)"
    },
    {
      backgroundColor: "rgba(119,163,53,0.7)",
      borderColor: "rgb(119,163,53)"
    },
    {
      backgroundColor: "rgba(43,132,183,0.7)",
      borderColor: "rgb(43,132,183)"
    },
    {
      backgroundColor: "rgba(205,60,60,0.7)",
      borderColor: "rgb(205,60,60)"
    },
    {
      backgroundColor: "rgba(134,83,183,0.7)",
      borderColor: "rgb(134,83,183)"
    },
    {
      backgroundColor: "rgba(235,188,32,0.7)",
      borderColor: "rgb(235,188,32)"
    },
    {
      backgroundColor: "rgba(59, 149, 149,0.7)",
      borderColor: "rgb(59, 149, 149)"
    },
    {
      backgroundColor: "rgba(161, 44, 86,0.7)",
      borderColor: "rgb(161, 44, 86)"
    },
    {
      backgroundColor: "rgba(46,86,150,0.7)",
      borderColor: "rgb(46,86,150)"
    },
    {
      backgroundColor: "rgba(212,126,198,0.7)",
      borderColor: "rgb(212,126,198)"
    },
    {
      backgroundColor: "rgba(129,86,53,0.7)",
      borderColor: "rgb(129,86,53)"
    },
    {
      backgroundColor: "rgba(61,127,60,0.7)",
      borderColor: "rgb(61,127,60)"
    },
    {
      backgroundColor: "rgba(204,98,44,0.7)",
      borderColor: "rgb(204,98,44)"
    },
    {
      backgroundColor: "rgba(132,132,132,0.7)",
      borderColor: "rgb(132,132,132)"
    },
    {
      backgroundColor: "rgba(190,195,77,0.7)",
      borderColor: "rgb(190,195,77)"
    }
  ];
  public lineChartColors = [];
  public lineChartOptions = {
    responsive: true,
    legend: {
      display: 'true',
      position: 'left'
    },
    scales: {
      xAxes: [{
        display: true,
        scaleLabel: {
          display: true,
          labelString: 'Années'
        }
      }],
      yAxes: [{
        display: true,
        scaleLabel: {
          display: true,
          labelString: "Nombre d'observations"
        }
      }]
    }
  };
  public lineChartLegend = true;

  constructor(public dataService: DataService, public fb: FormBuilder) {

  }

  ngOnInit() {
    // Accès aux années distinctes présentes dans la BDD GeoNature
    this.dataService.getYears({ type: "distinct" }).subscribe(
      (data) => {
        this.lineChartLabels.length = 0;
        // Remplissage de l'array des labels, paramètre du line chart
        data.forEach(
          (elt) => {
            this.lineChartLabels.push(elt[0]);
          }
        );
        console.log(this.lineChartLabels);
      }
    );

    // Accès aux noms des différents cadres d'acquisition présents dans la BDD GeoNature
    this.dataService.getFrameworksName().subscribe(
      (data) => {
        // Enregistrement des noms distincts de ces cadres d'acquisition
        data.forEach(
          (elt) => {
            this.frameworksName.push(elt[0]);
          }
        );
        this.nbFrameworks = this.frameworksName.length;
        // Sélection du nombre de couleurs correspondant
        this.lineChartColors = this.colors.slice(0, this.nbFrameworks);
        // Pour chaque cadre d'acquisition...
        this.frameworksName.forEach(
          (elt) => {
            // ... initialisation du dictionnaire qui va contenir les données le concernant
            var lineChartDataTemp = { data: [], label: elt, fill: false };
            // ... accès aux données
            this.dataService.getDataFrameworks({ frameworkName: elt }).subscribe(
              (data) => {
                // console.log(data);
                // Remplissage du dictionnaire, en tenant compte du fait qu'il peut n'y avoir aucune observation pour certains taxons
                const dataLength = data.length;
                var start = 0;
                this.lineChartLabels.forEach(
                  (year) => {
                    var i = start;
                    var keepGoing = true;
                    while ((i < dataLength) && (keepGoing == true)) {
                      if (year == data[i][0]) {
                        lineChartDataTemp.data.push(data[i][1]);
                        keepGoing = false;
                        start = i + 1;
                      }
                      i += 1;
                    }
                    if (keepGoing == true) {
                      lineChartDataTemp.data.push(0);
                    }
                  }
                );
                // Ajout du jeu de données (dictionnaire) à l'array des données, paramètre du line chart
                this.lineChartData.push(lineChartDataTemp);
              }
            );
          }
        );
        console.log(this.lineChartData);
        // console.log(this.chart);
      }
    );

  }

}
