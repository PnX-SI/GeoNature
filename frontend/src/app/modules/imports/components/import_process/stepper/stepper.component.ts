import { Component, Input } from '@angular/core';
import { Step } from '../../../models/enums.model';
import { ImportProcessService } from '../import-process.service';
import { ConfigService } from '@geonature/services/config.service';
import { Observable, of } from '@librairies/rxjs';

@Component({
  selector: 'stepper',
  styleUrls: ['stepper.component.scss'],
  templateUrl: 'stepper.component.html',
})
export class StepperComponent {
  @Input() step;
  public Step = Step;
  @Input() isObserverMappingAllowed: Observable<boolean> = of(false);

  constructor(
    public importProcessService: ImportProcessService,
    public config: ConfigService
  ) {}
}
