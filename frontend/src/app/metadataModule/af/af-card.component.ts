import { Component, OnInit, ViewChild, AfterViewInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { BaseChartDirective } from 'ng2-charts';
import { tap, map } from 'rxjs/operators';

import { DataFormService } from '@geonature_common/form/data-form.service';
import { AppConfig } from '@geonature_config/app.config';
import { CommonService } from '@geonature_common/service/common.service';

@Component({
  selector: 'pnx-af-card',
  templateUrl: './af-card.component.html',
  styleUrls: ['./af-card.component.scss'],
})
export class AfCardComponent implements OnInit {
  public id_af: number;
  public af: any;
  public stats: any;
  public bbox: any;
  public acquisitionFrameworks: any;
  @ViewChild(BaseChartDirective, { static: false }) chart: BaseChartDirective;
  // Type de graphe
  public pieChartType = 'doughnut';
  // Tableau contenant les labels du graphe
  public pieChartLabels = [];
  // Tableau contenant les données du graphe
  public pieChartData = [];
  // Tableau contenant les couleurs et la taille de bordure du graphe
  public pieChartColors = [];
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
        },
      },
    },
    plugins: {
      labels: [
        {
          render: 'label',
          arc: true,
          fontSize: 14,
          position: 'outside',
          overlap: false,
        },
        {
          render: 'percentage',
          fontColor: 'white',
          fontSize: 14,
          fontStyle: 'bold',
          precision: 2,
          textShadow: true,
          overlap: false,
        },
      ],
    },
  };

  public spinner = true;
  public APP_CONFIG = AppConfig;

  constructor(
    private _dfs: DataFormService,
    private _route: ActivatedRoute,
    private _router: Router,
    private _commonService: CommonService
  ) {}

  ngOnInit() {
    this._route.params.subscribe((params) => {
      this.id_af = params['id'];
      if (this.id_af) {
        this.getAf();
        this.getTaxaDistribution();
        this.getStats();
        this.getBbox();
      }
    });
  }

  getAf() {
    this._dfs
      .getAcquisitionFramework(this.id_af)
      .pipe(
        map((af) => {
          if (af.acquisition_framework_start_date) {
            af.acquisition_framework_start_date = new Date(
              af.acquisition_framework_start_date
            ).toLocaleDateString();
          }
          if (af.acquisition_framework_end_date) {
            af.acquisition_framework_end_date = new Date(
              af.acquisition_framework_end_date
            ).toLocaleDateString();
          }
          return af;
        })
      )
      .subscribe(
        (af) => (this.af = af),
        (err) => {
          if (err.status === 404) {
            this._commonService.translateToaster('error', 'MetaData.AF404');
          }
          this._router.navigate(['/metadata']);
        }
      );
  }

  getStats() {
    this._dfs.getAcquisitionFrameworkStats(this.id_af).subscribe((res) => (this.stats = res));
  }

  getBbox() {
    this._dfs.getAcquisitionFrameworkBbox(this.id_af).subscribe((res) => (this.bbox = res));
  }

  getTaxaDistribution() {
    this.spinner = true;
    this._dfs
      .getTaxaDistribution('group2_inpn', { id_af: this.id_af })
      .pipe(tap(() => (this.spinner = false)))
      .subscribe((res) => {
        this.pieChartData.length = 0;
        this.pieChartLabels.length = 0;
        this.pieChartData = [];
        this.pieChartLabels = [];
        for (let row of res) {
          this.pieChartData.push(row['count']);
          this.pieChartLabels.push(row['group']);
        }

        setTimeout(() => {
          this.chart && this.chart.chart.update();
        }, 1000);
      });
  }

  getPdf() {
    this._dfs.exportPDF(
      this.chart ? this.chart.toBase64Image() : '',
      `${AppConfig.API_ENDPOINT}/meta/acquisition_frameworks/export_pdf/${this.af.id_acquisition_framework}`,
      'af'
    );
  }
}
