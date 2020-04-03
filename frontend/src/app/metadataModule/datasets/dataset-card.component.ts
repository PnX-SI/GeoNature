import { Component, OnInit , ViewChild} from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { MetadataFormService } from '../services/metadata-form.service';
import { ModuleService } from '@geonature/services/module.service';
import { BaseChartDirective } from 'ng2-charts';

@Component({
  selector: 'pnx-datasets-form',
  templateUrl: './dataset-card.component.html',
  styleUrls: ['./dataset-card.scss'],
  providers: [MetadataFormService]
})

export class DatasetCardComponent implements OnInit {
  public organisms: Array<any>;
  public id_dataset: number;
  public dataset: any;
  public imports: Array<any>
  public nbTaxons: number;
  public nbObservations: number;
  
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
    private _route: ActivatedRoute,
    private _dfs: DataFormService,
    public moduleService: ModuleService
  ) {}

  ngOnInit() {
    // get the id from the route
    this._route.params.subscribe(params => {
      this.id_dataset = params['id'];
      if (this.id_dataset) {
        this.getDataset(this.id_dataset);
      }
    });
  }

  getDataset(id) {
    this._dfs.getDatasetDetails(id).subscribe(data => {
      this.dataset = data;

      this._dfs.getImports(id).subscribe(data => {
        this.imports = data;
        console.log(this.imports);
      })
    });
    this._dfs.getCountTaxon(id).subscribe(data => {
        this.nbTaxons = data;
    });
    this._dfs.getCountObservation(id).subscribe(data => {
        this.nbObservations = data;
    });
    this._dfs.getRepartitionTaxons(id).subscribe(data => {
      this.pieChartData.length = 0;
      this.pieChartLabels.length = 0;
        for(let row of data) {
          this.pieChartData.push(row[0]);
          this.pieChartLabels.push(row[1]);
        }
        this.chart.chart.update();
        this.chart.ngOnChanges({});
        this.spinner = false;
    });
    
  }
  
}
