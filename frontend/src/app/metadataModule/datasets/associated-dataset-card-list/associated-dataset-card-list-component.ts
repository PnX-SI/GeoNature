import { Component, Input } from '@angular/core';

@Component({
  selector: 'pnx-associated-dataset-card-list',
  templateUrl: './associated-dataset-card-list.component.html',
  styleUrls: ['../../association-list.scss'],
})
export class AssociatedDatasetCardListComponent {
  @Input() datasets: any[] = [];

  getDatasetIcon(nomenclatureCode?: string): string {
    switch (nomenclatureCode) {
      case '1':
        return './assets/images/Taxon_icon_vert.svg';
      case '2':
        return './assets/images/Habitat_icon_vert.svg';
      default:
        return './assets/images/Taxon_icon_vert.svg';
    }
  }
}
