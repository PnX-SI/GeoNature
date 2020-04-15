import { Component, OnInit, ViewChild } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { BaseChartDirective } from 'ng2-charts';
import { AppConfig } from '@geonature_config/app.config';

@Component({
  selector: 'pnx-af-card',
  templateUrl: './af-card.component.html',
  styleUrls: ['./af-card.component.scss'],
})
export class AfCardComponent implements OnInit {
  public id_af: number;
  public af: any;
  public acquisitionFrameworks: any;
  @ViewChild(BaseChartDirective) chart: BaseChartDirective;

  // Type de graphe
  public pieChartType = 'doughnut';
  // Tableau contenant les labels du graphe
  public pieChartLabels = [];
  // Tableau contenant les données du graphe
  public pieChartData = [];
  // Tableau contenant les couleurs et la taille de bordure du graphe
  public pieChartColors = [
    {
      backgroundColor: ["rgb(0,80,240)", "rgb(80,160,240)", "rgb(160,200,240)"],
    }
  ];
  // Dictionnaire contenant les options à implémenter sur le graphe (calcul des pourcentages notamment)
  public pieChartOptions = {
    cutoutPercentage: 80,
    legend: {
      display: 'true',
      position: 'left',
      labels: {
        fontSize: 15,
        filter: function (legendItem, chartData) {
          return chartData.datasets[0].data[legendItem.index] != 0;
        }
      },
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

  public spinner = true;

  constructor(
    private _dfs: DataFormService,
    private _route: ActivatedRoute
  ) { }

  ngOnInit() {
    this._route.params.subscribe(params => {
      this.id_af = params['id'];
      if (this.id_af) {
        this.getAf(this.id_af);
      }
    });
    // this._dfs.getAcquisitionFrameworks({ is_parent: 'true' }).subscribe(data => {
    //   this.acquisitionFrameworks = data;
    // });

    // console.log(this.acquisitionFrameworks);
  }
  getAf(id_af: number) {
    this._dfs.getAcquisitionFrameworkDetails(id_af).subscribe(data => {
      this.af = data;
      if (this.af.acquisition_framework_start_date) {
        var start_date = new Date(this.af.acquisition_framework_start_date);
        this.af.acquisition_framework_start_date = start_date.toLocaleDateString();
      }
      if (this.af.acquisition_framework_end_date) {
        var end_date = new Date(this.af.acquisition_framework_end_date);
        this.af.acquisition_framework_end_date = end_date.toLocaleDateString();
      }
      if(this.af.datasets)
      {
        if(this.af.datasets.length > 1){
          this._dfs.getTaxaDistribution(data.datasets).subscribe(data2 => {
            this.pieChartData.length = 0;
            this.pieChartLabels.length = 0;
            this.pieChartData = [];
            this.pieChartLabels = [];
              for(let row of data2) {
                this.pieChartData.push(row[0]);
                this.pieChartLabels.push(row[1]);
              }
              // this.chart.chart.update();
              // this.chart.ngOnChanges({});
              this.spinner = false;
          });
        }else if(this.af.datasets.length == 1){
          this._dfs.getRepartitionTaxons(data.datasets[0].id_dataset).subscribe(data2 => {
            this.pieChartData.length = 0;
            this.pieChartLabels.length = 0;
              for(let row of data2) {
                this.pieChartData.push(row[0]);
                this.pieChartLabels.push(row[1]);
              }
              // this.chart.chart.update();
              // this.chart.ngOnChanges({});
              this.spinner = false;
          });
        }
      }
      console.log(data);
    });
  }

  getPdf() {
    const url = `${AppConfig.API_ENDPOINT}/meta/acquisition_frameworks/export_pdf/${this.af.id_acquisition_framework}`;
    window.open(url);
  }
}
