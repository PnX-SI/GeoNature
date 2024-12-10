import { Component, Input } from '@angular/core';
import { MatIconModule } from '@angular/material/icon';
import { Indicator } from './indicator';
import { CommonModule } from '@angular/common';

@Component({
  standalone: true,
  selector: 'indicator',
  templateUrl: 'indicator.component.html',
  styleUrls: ['indicator.component.scss'],
  imports: [MatIconModule, CommonModule],
})
export class IndicatorComponent {
  @Input()
  indicator: Indicator;

  @Input()
  small: boolean = false;
}
