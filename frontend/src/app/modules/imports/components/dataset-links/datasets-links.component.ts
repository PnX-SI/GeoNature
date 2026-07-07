import { Component, Input } from '@angular/core';
import { RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-dataset-links',
  template: `
    <ng-container *ngFor="let datasetLink of datasetLinks; let last = last">
      <a [routerLink]="datasetLink.link">
        {{ datasetLink.name }}
      </a>
      <span *ngIf="!last">,</span>
    </ng-container>
  `,
  standalone: true,
  imports: [CommonModule, RouterModule],
})
export class DatasetLinksComponent {
  @Input() datasets: any[] = [];

  get datasetLinks(): { name: string; link: any[] }[] {
    if (!this.datasets || !this.datasets.length) {
      return [];
    }

    return this.datasets
      .filter((item) => item?.id_dataset && item?.dataset?.dataset_name)
      .map((item) => ({
        name: item.dataset.dataset_name,
        link: ['/metadata/dataset', item.id_dataset],
      }));
  }

  get tooltip(): string {
    return this.datasetLinks.map((link) => link.name).join(', ');
  }
}
