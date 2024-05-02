import { Component, OnChanges, OnInit, SimpleChanges } from '@angular/core';
import { Destination } from '@geonature/modules/imports/models/import.model';
import { ActivatedRoute } from '@angular/router';
import { ImportDataService } from '@geonature/modules/imports/services/data.service';
import { ImportProcessService } from '../import-process.service';

@Component({
  selector: 'header-stepper',
  styleUrls: ['header-stepper.component.scss'],
  templateUrl: 'header-stepper.component.html',
})
export class HeaderStepperComponent implements OnInit, OnChanges {
  private _destination: Destination | null;
  public destinationDataset: string = null;
  constructor(
    private _importDataService: ImportDataService,
    private _route: ActivatedRoute,
    private _importProcessService: ImportProcessService
  ) {}

  ngOnChanges(changes: SimpleChanges): void {
    this.updateDestinationDataset();
  }

  ngOnInit() {
    this._route.params.subscribe((params) => {
      this._importDataService.getDestination(params['destination']).subscribe((dest) => {
        this._destination = dest;
      });
      this._importProcessService.importDataUpdated.subscribe(() => {
        this.updateDestinationDataset();
      });
      this.updateDestinationDataset();
    });
  }

  /**
   * Updates the destination dataset based on the import data.
   *
   * This function retrieves the import data from the import process service and uses it to fetch the dataset from the import data service.
   *  If a dataset is found, its name is assigned to the destinationDataset property.
   *
   * @return {void}
   */
  updateDestinationDataset() {
    const importData = this._importProcessService.getImportData();
    if (!importData) return;
    this._importDataService.getDatasetFromId(importData.id_dataset).subscribe((dataset) => {
      if (dataset.dataset_name) {
        this.destinationDataset = dataset.dataset_name;
      }
    });
  }

  get destinationLabel(): string {
    return this._destination ? this._destination.label : '';
  }
}
