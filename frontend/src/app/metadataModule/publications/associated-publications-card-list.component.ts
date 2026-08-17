import { Component, Input } from '@angular/core';

@Component({
  selector: 'pnx-associated-publication-card-list',
  templateUrl: './associated-publications-card-list.component.html',
  styleUrls: ['../association-list.scss'],
})
export class AssociatedPublicationsCardListComponent {
  @Input() publications: any[] = [];
}
