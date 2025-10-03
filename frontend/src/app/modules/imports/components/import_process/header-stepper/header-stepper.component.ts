import { Component, OnChanges, OnInit, SimpleChanges } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { ImportDataService } from '@geonature/modules/imports/services/data.service';
import { ImportProcessService } from '../import-process.service';

interface ImportInfoBoxData {
  destinationName: string;
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
    this.updateImportInfo();
  }

  ngOnInit() {
    this._route.params.subscribe((params) => {
      this._importProcessService.importDataUpdated.subscribe(() => {
        this.updateImportInfo();
      });
      this.updateImportInfo(params);
    });
  }

  /**
   * Updates import infos.
   *
   * This function retrieves the import data from the import process service and uses it to update the info.
   *
   * @return {void}
   */
  updateImportInfo(params?: any) {
    const importData = this._importProcessService.getImportData();
    if (!importData && params) {
      this._importDataService.getDestination(params['destination']).subscribe((dest) => {
        this.infoBox = {
          destinationName: dest.label,
          fileName: undefined,
        };
      });
      return;
    }
    if (!importData) return;
    const { destination, full_file_name } = importData;
    this.infoBox = {
      destinationName: destination.label,
      fileName: full_file_name,
    };
  }
}
