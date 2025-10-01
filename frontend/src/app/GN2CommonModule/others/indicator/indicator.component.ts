import { Component, Input } from '@angular/core';
import { Indicator } from './indicator';

@Component({
  selector: 'pnx-indicator',
  templateUrl: 'indicator.component.html',
  styleUrls: ['indicator.component.scss'],
})
export class IndicatorComponent {
  @Input()
  indicator: Indicator;

  @Input()
  small: boolean = false;
}
