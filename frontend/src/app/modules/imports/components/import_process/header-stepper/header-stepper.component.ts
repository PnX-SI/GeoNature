import { Component, OnChanges, OnInit, SimpleChanges } from '@angular/core';
import { Destination } from '@geonature/modules/imports/models/import.model';
import { ActivatedRoute } from '@angular/router';
import { ImportDataService } from '@geonature/modules/imports/services/data.service';
import { ImportProcessService } from '../import-process.service';
import { data, param } from 'cypress/types/jquery';

interface ImportInfoBoxData {
  destinationName: string;
  destinationDatasetName?: string;
  fileName: string;
}

@Component({
  selector: 'header-stepper',
  styleUrls: ['header-stepper.component.scss'],
  templateUrl: 'header-stepper.component.html',
})
export class HeaderStepperComponent implements OnInit, OnChanges {
  public infoBox: ImportInfoBoxData;
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
      this._importProcessService.importDataUpdated.subscribe(() => {
        this.updateDestinationDataset();
      });
      this.updateDestinationDataset(params);
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
  updateDestinationDataset(params?: any) {
    const importData = this._importProcessService.getImportData();
    if (!importData && params) {
      this._importDataService.getDestination(params['destination']).subscribe((dest) => {
        this.infoBox = {
          destinationDatasetName: undefined,
          destinationName: dest.label,
          fileName: undefined,
        };
      });
      return;
    }
    const { dataset, destination, full_file_name } = importData;
    this.infoBox = {
      destinationDatasetName: dataset?.dataset_name,
      destinationName: destination.label,
      fileName: full_file_name,
    };
    console.log(1, this.infoBox);
  }
}
