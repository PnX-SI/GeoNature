import { Component, OnInit, ViewChild, AfterContentInit } from '@angular/core';
import { ActivatedRoute, Router, NavigationExtras } from '@angular/router';
import { BaseChartDirective } from 'ng2-charts';
import { BehaviorSubject } from 'rxjs';
import { tap, map } from 'rxjs/operators';
import { MatDialog } from "@angular/material";
import { TranslateService } from "@ngx-translate/core";

import { DataFormService } from '@geonature_common/form/data-form.service';
import { ModuleService } from '@geonature/services/module.service';
import { BaseChartDirective } from 'ng2-charts';
import { AppConfig } from "@geonature_config/app.config";
import { CommonService } from '@geonature_common/service/common.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { ConfirmationDialog } from "@geonature_common/others/modal-confirmation/confirmation.dialog";
import { MetadataDataService } from "../services/metadata-data.service";


@Component({
  selector: 'pnx-datasets-card',
  templateUrl: './dataset-card.component.html',
  styleUrls: ['./dataset-card.scss']
})
export class DatasetCardComponent implements OnInit {

  public id_dataset: number;
  public dataset: any;
  public nbTaxons: number = null;
  public nbObservations: number = null;
  public bbox: any = null;
  public imports: any = [];
  public taxs;

  @ViewChild(BaseChartDirective) public chart: BaseChartDirective;

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
  };

  public spinner = true;

  private _moduleImportIsAuthorized: BehaviorSubject<boolean> = new BehaviorSubject(false);
  get moduleImportIsAuthorized() {
    return this._moduleImportIsAuthorized.getValue();
  }

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
  ) { }

  ngOnInit() {
    // get the id from the route
    this._route.params.subscribe(params => {
      this.id_dataset = params['id'];
      if (this.id_dataset) {
        this.getData();
      }
    });
  }

  getData() {
    this._dataService.getObsCount({'id_dataset': this.id_dataset})
      .subscribe((res: number) => this.nbObservations = res);

    this._dataService.getTaxaCount({'id_dataset': this.id_dataset})
      .subscribe((res: number) => this.nbTaxons = res);

    this._dataService.getObsBbox({'id_dataset': this.id_dataset})
      .subscribe((res: any) => this.bbox = res);

    this.metadataDataS.getdatasetImports(this.id_dataset)
      .subscribe((res: any) => this.imports = res);

    this._dfs.getDataset(this.id_dataset)
      .subscribe(dataset => this.dataset = dataset);

    this._dfs.getTaxaDistribution('group2_inpn', { id_dataset: this.id_dataset }).subscribe(data => {
      this.pieChartData = [];
      this.pieChartLabels = [];
      for (let row of data) {
        this.pieChartData.push(row['count']);
        this.pieChartLabels.push(row['group']);
      }
      // in order to have chart instance
      setTimeout(() => {
        this.chart.chart.update();
      }, 1000);
    });

    //vérification que l'utilisateur est autorisé à utiliser le module d'import
    this.moduleService.moduleSub
      .pipe(
        map((modules: any[]): boolean => {
          if (modules) {
            for (let i = 0; i < modules.length; i++) {
              //recherche du module d'import et test si l'utilisateur a des droits dessus
              if (modules[i].module_code == 'IMPORT' && modules[i].cruved['C'] > 0) {
                return true;
              }
            }
          }
          return false;
        })
      )
      .subscribe((importIsAuthorized: boolean) => this._moduleImportIsAuthorized.next(importIsAuthorized));

  }

  uuidReport(ds_id) {
    this._dataService.downloadUuidReport(
      `UUID_JDD-${ds_id}_${this.dataset.unique_dataset_id}`,
      { id_dataset: ds_id }
    );
  }

  sensiReport(ds_id) {
    this._dataService.downloadSensiReport(
      `Sensibilite_JDD-${ds_id}_${this.dataset.unique_dataset_id}`,
      { id_dataset: ds_id }
    );
  }

  getPdf() {
    const url = `${AppConfig.API_ENDPOINT}/meta/dataset/export_pdf/${this.id_dataset}`;
    const dataUrl = this.chart ? this.chart.ctx.canvas.toDataURL('image/png') : '';
    this._dfs.uploadCanvas(dataUrl).subscribe(data => {
      console.log(url);

      window.open(url);
    });
  }

  uuidReportImport(id_import) {
    const imp = this.dataset.imports.find(imp => imp.id_import == id_import);
    this._dataService.downloadUuidReport(
      `UUID_Import-${id_import}_JDD-${imp.id_dataset}`,
      { id_import: id_import }
    );
  }

  sensiReportImport(id_import) {
    console.log("OK");
    const imp = this.dataset.imports.find(imp => imp.id_import == id_import);
    this._dataService.downloadSensiReport(
      `Sensibilite_Import-${id_import}_JDD-${imp.id_dataset}`,
      { id_import: id_import }
    );
  }

  delete_Dataset(idDataset) {
    if (window.confirm('Etes-vous sûr de vouloir supprimer ce jeu de données ?')) {
      this._dfs.deleteDs(idDataset).subscribe(d => {
        this._router.navigate(['metadata'])
      });
    }
  }
  deleteDataset(dataset) {
    const message = `${this.translate.instant("Delete")} ${dataset.dataset_name} ?`;
    const dialogRef = this.dialog.open(ConfirmationDialog, {
      width: "350px",
      position: { top: "5%" },
      data: { message: message },
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this._dfs.deleteDs(dataset.id_dataset)
          .pipe(
            tap(() => this._commonService.translateToaster("success", "MetaData.DatasetRemoved"))
          )
          .subscribe(
            () => this._router.navigate(['metadata']),
            err => {
              if (err.error.message) {
                this._commonService.regularToaster("error", err.error.message);
              } else {
                this._commonService.translateToaster("error", "ErrorMessage");
              }
             }
          );
      }
    });
  }

  importDs(idDataset) {
    let navigationExtras: NavigationExtras = {
      queryParams: {
        "datasetId": idDataset,
        "resetStepper": true
      }
    };
    this._router.navigate(['/import/process/step/1'], navigationExtras);
  }

  syntheseDs(idDataset) {
    let navigationExtras: NavigationExtras = {
      queryParams: {
        "id_dataset": idDataset
      }
    };
    this._router.navigate(['/synthese'], navigationExtras);
  }

}
