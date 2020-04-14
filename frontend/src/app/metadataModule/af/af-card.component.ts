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
  public datasets: any;
  @ViewChild(BaseChartDirective) chart: BaseChartDirective;

  // Type de graphe
  public pieChartType = 'doughnut';
  // Tableau contenant les labels du graphe
  public pieChartLabels = ['OK', 'WARNING', 'CRITICAL', 'UNKNOWN'];
  // Tableau contenant les données du graphe
  public pieChartData = [12, 19, 3, 5];
  // Tableau contenant les couleurs et la taille de bordure du graphe
  public pieChartColors = [
    {
      backgroundColor: ['rgb(0,80,240)', 'rgb(80,160,240)', 'rgb(160,200,240)'],
    }
  ];
  // Dictionnaire contenant les options à implémenter sur le graphe (calcul des pourcentages notamment)
  public pieChartOptions = {
    weight: "0.2",
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
        this.getDatasets(this.id_af);
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

      console.log(data);
    });
  }

  getDatasets(id_af: number) {
    var params: { [key: string]: any; } = {};
    params["id_acquisition_frameworks"] = [id_af];
    this._dfs.getDatasets(params, false).subscribe(results => {
      this.datasets = results["data"];
      // this.getImports();
      console.log(this.datasets)
    });

  }

  getImports() {
    for (let i = 0; i < this.datasets.length; i++) {
      this._dfs.getImports(this.datasets[i]["id_dataset"]).subscribe(data => {
        this.datasets[i]['imports'] = data;
      });
    }
  }

  getPdf() {
    const url = `${AppConfig.API_ENDPOINT}/meta/acquisition_frameworks/export_pdf/${this.af.id_acquisition_framework}`;
    window.open(url);
  }
}
