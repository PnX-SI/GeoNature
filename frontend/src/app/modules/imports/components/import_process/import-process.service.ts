import { EventEmitter, Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { Step } from '../../models/enums.model';
import { Import } from '../../models/import.model';
import { ConfigService } from '@geonature/services/config.service';
import { ImportDataService } from '../../services/data.service';

@Injectable()
export class ImportProcessService {
  private importData: Import | null = null;
  public importDataUpdated: EventEmitter<any> = new EventEmitter();
  private isObserverMappingAllowed: boolean = false;

  constructor(
    private router: Router,
    public config: ConfigService,
    private _importDataService: ImportDataService
  ) {}

  setImportData(importData: Import) {
    this.importData = importData;
    this._importDataService.isObserverMappingAllowed().subscribe((isAllowed) => {
      this.isObserverMappingAllowed = isAllowed;
      this.importDataUpdated.emit();
    });
  }

  getImportData(): Import | null {
    return this.importData;
  }

  getLastAvailableStep(): Step {
    let lastAvailableStep = Step.Import;
    if (!this.importData.full_file_name) {
      lastAvailableStep = Step.Upload;
    } else if (!this.importData.columns || !this.importData.columns.length) {
      lastAvailableStep = Step.Decode;
    } else if (!this.importData.loaded) {
      lastAvailableStep = Step.FieldMapping;
    } else if (!this.importData.contentmapping) {
      lastAvailableStep = Step.ContentMapping;
    }
    return lastAvailableStep;
  }

  resetImportData() {
    this.importData = null;
  }

  getRouterLinkForStep(step: Step): any[] | null {
    if (this.importData == null || this.importData.destination == null) return null;
    let stepName = Step[step].toLowerCase();
    let importId: number = this.importData.id_import;
    let destinationCode: string = this.importData.destination.code;
    return [this.config.IMPORT.MODULE_URL, destinationCode, 'process', importId, stepName];
  }

  navigateToStep(step: Step) {
    const link = this.getRouterLinkForStep(step);
    if (link) {
      this.router.navigate(link);
    }
  }

  // If some steps must be skipped, implement it here
  getPreviousStep(step: Step): Step {
    let previousStep = step - 1;
    if (!this.isObserverMappingAllowed && previousStep === Step.ContentMapping) {
      previousStep -= 1;
    }
    if (!this.isObserverMappingAllowed && previousStep === Step.ObserverMapping) {
      previousStep -= 1;
    }
    return previousStep;
  }

  // If some steps must be skipped, implement it here
  getNextStep(step: Step): Step {
    let nextStep = step + 1;
    if (!this.isObserverMappingAllowed && nextStep === Step.ContentMapping) {
      nextStep += 1;
    }
    if (!this.isObserverMappingAllowed && nextStep === Step.ObserverMapping) {
      nextStep += 1;
    }

    return nextStep;
  }

  navigateToPreviousStep(step: Step) {
    this.navigateToStep(this.getPreviousStep(step));
  }

  navigateToNextStep(step: Step) {
    this.navigateToStep(this.getNextStep(step));
  }

  navigateToLastStep() {
    this.navigateToStep(this.getLastAvailableStep());
  }

  beginProcess(destination: string) {
    const link = [
      this.config.IMPORT.MODULE_URL,
      destination,
      'process',
      Step[Step.Upload].toLowerCase(),
    ];
    this.router.navigate(link);
  }

  continueProcess(importData: Import) {
    this.importData = importData;
    this.navigateToStep(this.getLastAvailableStep());
  }

  checkImportDone(importData: Import): boolean {
    return !!importData?.date_end_import;
  }

  get isImportCompleted(): boolean {
    return this.importData ? this.checkImportDone(this.importData) : false;
  }
}
