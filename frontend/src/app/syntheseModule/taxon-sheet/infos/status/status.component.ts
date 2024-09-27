import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';

@Component({
  standalone: true,
  selector: 'status',
  templateUrl: 'status.component.html',
  styleUrls: ['status.component.scss'],
  imports: [CommonModule, GN2CommonModule],
})
export class StatusComponent {
  constructor() {}

  @Input()
  taxon: Taxon | null;
}
