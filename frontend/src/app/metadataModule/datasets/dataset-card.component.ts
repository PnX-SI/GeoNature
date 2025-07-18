import { Component, OnInit, ViewChild } from '@angular/core';
import { ActivatedRoute, Router, NavigationExtras } from '@angular/router';
import { BaseChartDirective } from 'ng2-charts';
import { tap } from 'rxjs/operators';
import { MatDialog } from '@angular/material/dialog';
import { TranslateService } from '@ngx-translate/core';
import DatalabelsPlugin from 'chartjs-plugin-datalabels';

import { DataFormService } from '@geonature_common/form/data-form.service';
import { ModuleService } from '@geonature/services/module.service';
import { CommonService } from '@geonature_common/service/common.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { ConfirmationDialog } from '@geonature_common/others/modal-confirmation/confirmation.dialog';
import { MetadataDataService } from '../services/metadata-data.service';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-datasets-card',
  templateUrl: './dataset-card.component.html',
  styleUrls: ['./dataset-card.scss'],
})
export class DatasetCardComponent implements OnInit {
  public id_dataset: number;
  public dataset: any;
  public nbTaxons: number = null;
  public nbObservations: number = null;
  public bbox: any = null;
  public taxs;

  @ViewChild(BaseChartDirective, { static: false }) public chart: BaseChartDirective;

  public pieChartPlugins = [DatalabelsPlugin];
  // Tableau contenant les labels du graphe
  public pieChartLabels = [];
  // Tableau contenant les données du graphe
  public pieChartData = [
    {
      data: [],
    },
  ];
  public pieChartOptions = {
    plugins: {
      datalabels: {
        formatter: (value, context) => {
          const total = context.chart.data.datasets[0].data.reduce((acc, prev) => acc + prev);
          const percentage = Math.round((value / total) * 100);
          return percentage < 5 ? null : percentage + '%';
        },
      },
    },
  };

  public spinner = true;

  constructor(
    private _route: ActivatedRoute,
    private _dfs: DataFormService,
    private translate: TranslateService,
    public moduleService: ModuleService,
    private _commonService: CommonService,
    public _dataService: SyntheseDataService,
    private _router: Router,
    public dialog: MatDialog,
    public metadataDataS: MetadataDataService,
    public config: ConfigService
  ) {}

  ngOnInit() {
    // get the id from the route
    this._route.params.subscribe((params) => {
      this.id_dataset = params['id'];
      if (this.id_dataset) {
        this.getData();
      }
    });
  }

  getData() {
    this._dataService
      .getObsCount({ id_dataset: this.id_dataset })
      .subscribe((res: number) => (this.nbObservations = res));

    this._dataService
      .getTaxaCount({ id_dataset: this.id_dataset })
      .subscribe((res: number) => (this.nbTaxons = res));

    this._dataService
      .getObsBbox({ id_dataset: this.id_dataset })
      .subscribe((res: any) => (this.bbox = res));

    this._dfs.getDataset(this.id_dataset).subscribe((dataset) => (this.dataset = dataset));

    this._dfs
      .getTaxaDistribution('group2_inpn', { id_dataset: this.id_dataset })
      .subscribe((data) => {
        this.pieChartData[0].data = [];
        this.pieChartLabels = [];
        for (let row of data) {
          this.pieChartData[0].data.push(row['count']);
          this.pieChartLabels.push(row['group']);
        }
        // in order to have chart instance
        setTimeout(() => {
          this.chart && this.chart.chart.update();
        }, 1000);
      });
  }

  uuidReport(ds_id) {
    this._dataService.downloadUuidReport(`UUID_JDD-${ds_id}_${this.dataset.unique_dataset_id}`, {
      id_dataset: ds_id,
    });
  }

  sensiReport(ds_id) {
    this._dataService.downloadSensiReport(
      `Sensibilite_JDD-${ds_id}_${this.dataset.unique_dataset_id}`,
      { id_dataset: ds_id }
    );
  }

  getPdf() {
    this._dfs.exportPDF(
      this.chart ? this.chart.toBase64Image() : '',
      `${this.config.API_ENDPOINT}/meta/dataset/export_pdf/${this.id_dataset}`,
      'jdd'
    );
  }

  delete_Dataset(idDataset) {
    if (window.confirm('Etes-vous sûr de vouloir supprimer ce jeu de données ?')) {
      this._dfs.deleteDs(idDataset).subscribe((d) => {
        this._router.navigate(['metadata']);
      });
    }
  }

  deleteDataset(dataset) {
    const message = `${this.translate.instant('Actions.Delete')} ${dataset.dataset_name} ?`;
    const dialogRef = this.dialog.open(ConfirmationDialog, {
      width: '350px',
      position: { top: '5%' },
      data: { message: message },
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this._dfs
          .deleteDs(dataset.id_dataset)
          .pipe(
            tap(() =>
              this._commonService.translateToaster('success', 'MetaData.Messages.DatasetRemoved')
            )
          )
          .subscribe(() => this._router.navigate(['metadata']));
      }
    });
  }

  useModuleWithDs(module) {
    this._router.navigateByUrl(module?.input_url);
  }

  hasAnyButtons() {
    return this.dataset?.cruved?.E || this.dataset?.modules?.some((m) => m.input_url);
  }

  syntheseDs(idDataset) {
    let navigationExtras: NavigationExtras = {
      queryParams: {
        id_dataset: idDataset,
      },
    };
    this._router.navigate(['/synthese'], navigationExtras);
  }
}
