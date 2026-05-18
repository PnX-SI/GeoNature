import { Component, Input, OnInit } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { tap, map } from 'rxjs/operators';
import { MetadataDataService } from '../services/metadata-data.service';
import { ActionService } from '@geonature/services/action.service';

@Component({
  selector: 'pnx-dataset-activation-toggle',
  templateUrl: './dataset-activation-toggle.component.html',
})
export class DatasetActivationToggleComponent implements OnInit {
  @Input() dataset: any;
  @Input() acquisitionFramework: any;

  stateChangeSaving: boolean = false;

  constructor(
    private translate: TranslateService,
    private metadataDataS: MetadataDataService,
    private actionService: ActionService
  ) {}

  ngOnInit() {}

  isSwitchable(): boolean {
    return this.actionService.isActionAllowed(
      this.dataset.cruved,
      this.acquisitionFramework.opened,
      'U'
    );
  }

  getTooltip(): string {
    if (!this.isSwitchable()) {
      return this.actionService.getActionTooltip(
        this.dataset.cruved,
        this.acquisitionFramework.opened,
        'U',
        'MetaData'
      );
    }
    return this.dataset.active
      ? this.translate.instant('MetaData.Tooltips.DatasetActive')
      : this.translate.instant('MetaData.Tooltips.DatasetInactive');
  }

  switchDatasetState(event: any): void {
    this.stateChangeSaving = true;
    this.metadataDataS
      .patchDataset(this.dataset.id_dataset, { active: event.checked })
      .pipe(
        tap(() => (this.stateChangeSaving = false)),
        map((res: any): boolean => res.active)
      )
      .subscribe((state: boolean) => (this.dataset.active = state));
  }
}
