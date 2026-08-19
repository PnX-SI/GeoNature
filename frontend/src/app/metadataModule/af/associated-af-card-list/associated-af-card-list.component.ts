import { Component, Input } from '@angular/core';

@Component({
  selector: 'pnx-associated-af-card-list',
  templateUrl: './associated-af-card-list.component.html',
  styleUrls: ['../../association-list.scss'],
})
export class AssociatedAfCardListComponent {
  @Input() acquisitionFrameworks: any[] = [];

  getAfIcon(): string {
    return './assets/images/Taxon_icon_vert.svg';
  }
}
