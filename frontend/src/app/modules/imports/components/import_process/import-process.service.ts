import { Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { Step } from '../../models/enums.model';
import { Import } from '../../models/import.model';
import { ConfigService } from '@geonature/services/config.service';

@Injectable()
export class ImportProcessService {
  private importData: Import | null = null;

  constructor(
    private router: Router,
    public config: ConfigService
  ) {}

  setImportData(importData: Import) {
    this.importData = importData;
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

  getRouterLinkForStep(step: Step) {
    if (this.importData == null) return null;
    let stepName = Step[step].toLowerCase();
    let importId: number = this.importData.id_import;
    let destinationCode: string = this.importData.destination.code;
    return [this.config.IMPORT.MODULE_URL, destinationCode, 'process', importId, stepName];
  }

  navigateToStep(step: Step) {
    this.router.navigate(this.getRouterLinkForStep(step));
  }

  // If some steps must be skipped, implement it here
  getPreviousStep(step: Step): Step {
    let previousStep = step - 1;
    if (!this.config.IMPORT.ALLOW_VALUE_MAPPING && previousStep === Step.ContentMapping) {
      previousStep -= 1;
    }
    return previousStep;
  }

  // If some steps must be skipped, implement it here
  getNextStep(step: Step): Step {
    let nextStep = step + 1;
    if (!this.config.IMPORT.ALLOW_VALUE_MAPPING && nextStep === Step.ContentMapping) {
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
    const link = [this.config.IMPORT.MODULE_URL, destination, 'process', Step[Step.Upload].toLowerCase()];
    this.router.navigate(link);
  }

  continueProcess(importData: Import) {
    this.importData = importData;
    this.navigateToStep(this.getLastAvailableStep());
  }
}
