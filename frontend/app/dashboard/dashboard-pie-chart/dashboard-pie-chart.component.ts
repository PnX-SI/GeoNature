import { Component, OnInit, ViewChild, Input } from "@angular/core";
import { FormBuilder, FormGroup } from "@angular/forms";
import { BaseChartDirective } from 'ng2-charts/ng2-charts';
// Services
import { DataService } from "../services/data.services";

@Component({
  selector: "dashboard-pie-chart",
  templateUrl: "dashboard-pie-chart.component.html",
  styleUrls: ['./dashboard-pie-chart.component.scss']
})

export class DashboardPieChartComponent implements OnInit {

  @ViewChild(BaseChartDirective) chart: BaseChartDirective;

  public subscription: any;
  public pieChartType = 'doughnut';
  public pieChartLabels = [];
  public pieChartData = [];
  public backgroundColors = ["rgb(217,146,30)", "rgb(119,163,53)", "rgb(43,132,183)", "rgb(205,60,60)", "rgb(134,83,183)", "rgb(235,188,32)", "rgb(59, 149, 149)", "rgb(161, 44, 86)", "rgb(46,86,150)", "rgb(212,126,198)", "rgb(129,86,53)", "rgb(61,127,60)", "rgb(204,98,44)", "rgb(132,132,132)", "rgb(190,195,77)", "rgb(97,187,223)", "rgb(224,186,140)", "rgb(169,45,152)", "rgb(94, 207, 178)", "rgb(66,81,126)", "rgb(101,33,33)", "rgb(117,112,56)", "rgb(191,158,46)", "rgb(147,75,75)", "rgb(64,64,64)", "rgb(169,130,211)", "rgb(51,102,82)", "rgb(245,133,120)", "rgb(167,110,33)", "rgb(229,226,222)"];
  public pieChartColors = [
    {
      backgroundColor: this.backgroundColors.concat(this.backgroundColors, this.backgroundColors, this.backgroundColors, this.backgroundColors, this.backgroundColors, this.backgroundColors, this.backgroundColors, this.backgroundColors, this.backgroundColors),
      borderWidth: 0.8
    },
    {
      backgroundColor: this.backgroundColors.concat(this.backgroundColors, this.backgroundColors, this.backgroundColors, this.backgroundColors, this.backgroundColors, this.backgroundColors, this.backgroundColors, this.backgroundColors, this.backgroundColors),
      borderWidth: 0.8
    }
  ];
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
        // {
        //   render: 'label',
        //   fontSize: 14,
        //   position: 'outside',
        //   arc: true,
        //   overlap: false
        // },
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

  pieChartForm: FormGroup;
  @Input() taxonomies: any;
  @Input() yearsMinMax: any;
  public yearRange = [1980, 2019];
  public spinner = false;

  constructor(public dataService: DataService, public fb: FormBuilder) {
    // Déclaration du formulaire contenant les filtres du pie chart
    this.pieChartForm = fb.group({
      selectedYearRange: fb.control(this.yearRange),
      selectedFilter: fb.control(null)
    });
  }

  ngOnInit() {
    this.spinner = true;
    // Initialisation de l'array des labels, paramètre du pie chart
    this.pieChartLabels = this.taxonomies["Règne"];
    // Par défaut, le pie chart s'affiche au niveau du règne
    this.pieChartForm.controls["selectedFilter"].setValue("Règne");
    // Accès aux données de synthèse de la BDD GeoNature
    this.subscription = this.dataService.getDataSynthesePerTaxLevel(this.pieChartForm.value).subscribe(
      (data) => {
        console.log(data);
        //Remplissage de l'array des données, paramètre du pie chart
        data.forEach(
          (elt) => {
            this.pieChartData.push(elt[1]);
          }
        );
        this.chart.chart.update();
        console.log(this.pieChartData);
        this.spinner = false;
      }
    );
  }

  ngOnChanges(change) {
    // Récupération des années min et max présentes dans les données de synthèse de la BDD GeoNature
    if (change.yearsMinMax && change.yearsMinMax.currentValue != undefined) {
      this.yearRange = change.yearsMinMax.currentValue;
    }
  }

  // Rafraichissement des données en fonction des filtres renseignés par l'utilisateur
  getCurrentParameters(event) {
    this.subscription.unsubscribe();
    this.spinner = true;
    // console.log(event);
    // S'il s'agit d'un changement de rang taxonomique : réinitialisation de l'array de la légende
    if (event.target) {
      this.pieChartLabels = this.taxonomies[event.target.value];
      console.log(this.pieChartLabels);
    }
    // Réinitialisation de l'array des données à afficher, paramètre du pie chart
    var pieChartDataTemp = [];
    // Accès aux données de synthèse de la BDD GeoNature
    this.subscription = this.dataService.getDataSynthesePerTaxLevel(this.pieChartForm.value).subscribe(
      (data) => {
        console.log(data);
        // Remplissage de l'array des données, en tenant compte du fait qu'il peut n'y avoir aucune observation pour certains taxons
        const dataLength = data.length;
        var start = 0;
        this.pieChartLabels.forEach(
          (taxon) => {
            var i = start;
            var keepGoing = true;
            while ((i < dataLength) && (keepGoing == true)) {
              if (taxon == data[i][0]) {
                pieChartDataTemp.push(data[i][1]);
                keepGoing = false;
                start = i + 1;
              }
              i += 1;
            }
            if (keepGoing == true) {
              pieChartDataTemp.push(0);
            }
          }
        );
        // console.log(pieChartDataTemp);
        this.pieChartData = pieChartDataTemp;
        this.spinner = false;
        console.log(this.pieChartData);
      }
    );
  }

}
