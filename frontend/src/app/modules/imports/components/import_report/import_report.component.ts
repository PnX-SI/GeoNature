import { Component, OnInit, ViewChild } from "@angular/core";
import { Router } from "@angular/router";
import { saveAs } from "file-saver";
import leafletImage from "leaflet-image";
import { BaseChartDirective } from "ng2-charts";

import { MapService } from "@geonature_common/map/map.service";
import { DataService } from "../../services/data.service";
import { ImportProcessService } from "../import_process/import-process.service";
import {
  Import,
  ImportError,
  Nomenclature,
  NomenclatureType,
  TaxaDistribution,
} from "../../models/import.model";
import { ConfigService } from "@geonature/services/config.service";
import { CsvExportService } from "../../services/csv-export.service";

interface MatchedNomenclature {
  source: Nomenclature;
  target: Nomenclature;
}

@Component({
  selector: "pnx-import-report",
  templateUrl: "import_report.component.html",
  styleUrls: ["import_report.component.scss"],
})
export class ImportReportComponent implements OnInit {
  @ViewChild(BaseChartDirective) chart: BaseChartDirective;
  readonly maxErrorsLines: number = 10;
  readonly rankOptions: string[] = [
    "regne",
    "phylum",
    "classe",
    "ordre",
    "famille",
    "sous_famille",
    "tribu",
    "group1_inpn",
    "group2_inpn",
  ];
  public importData: Import | null;
  public expansionPanelHeight: string = "60px";
  public validBbox: any;
  public taxaDistribution: Array<TaxaDistribution> = [];
  public importErrors: Array<ImportError> = [];
  public importWarnings: Array<ImportError> = [];
  public nbTotalErrors: number = 0;
  public datasetName: string = "";
  public rank: string = null;
  public doughnutChartLabels: Array<String> = [];
  public doughnutChartData: Array<any> = [{ data: [] }];

  public doughnutChartType: string = "doughnut";
  public options: any = {
    legend: { position: "left" },
  };
  public loadingPdf: boolean = false;
  public importStatus: string = "EN COURS";
  public importStatusClass: string = "unfinished";
  public nomenclatures: {
    [propName: string]: {
      nomenclature_type: NomenclatureType;
      nomenclatures: {
        [propName: string]: Nomenclature;
      };
    };
  };

  constructor(
    private importProcessService: ImportProcessService,
    private _dataService: DataService,
    private _router: Router,
    private _map: MapService,
    public _csvExport: CsvExportService,
    public config: ConfigService
  ) {
    this.rank = this.rankOptions.includes(this.config.IMPORT.DEFAULT_RANK)
      ? this.config.IMPORT.DEFAULT_RANK
      : this.rankOptions[0];
  }

  ngOnInit() {
    this.importData = this.importProcessService.getImportData();
    // Load additionnal data if imported data
    this.loadValidData(this.importData);
    this.loadTaxaDistribution();
    this.loadDatasetName();
    // Add property to show errors lines. Need to do this to
    // show line per line...
    this.loadErrors();
    this.setImportStatus();
    this._dataService.getNomenclatures().subscribe((nomenclatures) => {
      this.nomenclatures = nomenclatures;
    });
  }

  /** Gets the validBbox and validData (info about observations)
   * @param {string}  idImport - id of the import to get the info from
   */
  loadValidData(importData: Import | null) {
    if (importData) {
      if (importData.date_end_import && importData.id_source) {
        this._dataService.getBbox(importData.id_source).subscribe((data) => {
          this.validBbox = data;
        });
      } else if (importData.processed) {
        this._dataService
          .getValidData(importData?.id_import)
          .subscribe((data) => {
            this.validBbox = data.valid_bbox;
          });
      }
    }
  }

  loadTaxaDistribution() {
    const idSource: number | undefined = this.importData?.id_source;
    if (idSource) {
      this._dataService
        .getTaxaRepartition(idSource, this.rank)
        .subscribe((data) => {
          this.taxaDistribution = data;
          this.updateChart();
        });
    }
  }

  loadDatasetName() {
    if (this.importData) {
      this._dataService
        .getDatasetFromId(this.importData.id_dataset)
        .subscribe((data) => {
          this.datasetName = data.dataset_name;
        });
    }
  }

  loadErrors() {
    if (this.importData) {
      this._dataService
        .getImportErrors(this.importData.id_import)
        .subscribe((errors) => {
          this.importErrors = errors.filter((err) => {
            return err.type.level === "ERROR";
          });
          this.importWarnings = errors.filter((err) => {
            return err.type.level === "WARNING";
          });
          // Get the total number of erroneous rows:
          // 1. get all rows in errors
          // 2. flaten to have 1 array of all rows in error
          // 3. remove duplicates (with Set)
          // 4. return the size of the Set (length)
          this.nbTotalErrors = new Set(
            errors
              .map((item) => item.rows)
              .reduce((acc, val) => acc.concat(val), [])
          ).size;
        });
    }
  }

  updateChart() {
    const labels: string[] = this.taxaDistribution.map((e) => e.group);
    const data: number[] = this.taxaDistribution.map((e) => e.count);

    this.doughnutChartLabels.length = 0;
    // Must push here otherwise the chart will not update
    this.doughnutChartLabels.push(...labels);

    this.doughnutChartData[0].data.length = 0;
    this.doughnutChartData[0].data = data;
    this.chart.chart.update();
  }

  getChartPNG(): HTMLImageElement {
    const chart: HTMLCanvasElement = <HTMLCanvasElement>(
      document.getElementById("chart")
    );
    const img: HTMLImageElement = document.createElement("img");
    if (chart) {
      img.src = chart.toDataURL();
    }
    return img;
  }

  exportFieldMapping() {
    // this.fields can be null
    // 4 : tab size
    if (this.importData?.fieldmapping) {
      const blob: Blob = new Blob(
        [JSON.stringify(this.importData.fieldmapping, null, 4)],
        {
          type: "application/json",
        }
      );
      saveAs(blob, `${this.importData?.id_import}_correspondances_champs.json`);
    }
  }

  exportContentMapping() {
    // Exactly like the correspondances
    if (this.importData?.contentmapping) {
      const blob: Blob = new Blob(
        [JSON.stringify(this.importData.contentmapping, null, 4)],
        {
          type: "application/json",
        }
      );
      saveAs(
        blob,
        `${this.importData?.id_import}_correspondances_nomenclatures.json`
      );
    }
  }

  exportAsPDF() {
    const img: HTMLImageElement = document.createElement("img");
    this.loadingPdf = true;
    const chartImg: HTMLImageElement = this.getChartPNG();

    if (this._map.map) {
      leafletImage(
        this._map.map ? this._map.map : "",
        function (err, canvas) {
          img.src = canvas.toDataURL("image/png");
          this.exportMapAndChartPdf(chartImg, img);
        }.bind(this)
      );
    } else {
      this.exportMapAndChartPdf(chartImg);
    }
  }

  downloadSourceFile() {
    this._dataService
      .downloadSourceFile(this.importData?.id_import)
      .subscribe((result) => {
        saveAs(result, this.importData?.full_file_name);
      });
  }

  setImportStatus() {
    if (this.importData?.task_progress === -1) {
      this.importStatus = "EN ERREUR";
      this.importStatusClass = "inerror";
    } else if (this.importData?.date_end_import) {
      this.importStatus = "TERMINE";
      this.importStatusClass = "importdone";
    }
  }

  exportMapAndChartPdf(chartImg?, mapImg?) {
    this._dataService
      .getPdf(this.importData?.id_import, mapImg?.src, chartImg.src)
      .subscribe(
        (result) => {
          this.loadingPdf = false;
          saveAs(result, "export.pdf");
        },
        (error) => {
          this.loadingPdf = false;
          console.log("Error getting pdf");
        }
      );
  }

  goToSynthese(idDataSet: number) {
    let navigationExtras = {
      queryParams: {
        id_dataset: idDataSet,
      },
    };
    this._router.navigate(["/synthese"], navigationExtras);
  }

  onRankChange($event) {
    this.loadTaxaDistribution();
  }
  navigateToImportList() {
    this._router.navigate([this.config.IMPORT.MODULE_URL]);
  }
}
