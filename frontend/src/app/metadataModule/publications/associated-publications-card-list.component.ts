import { Component, Input } from '@angular/core';
import { Association, Publication } from '@geonature/metadataModule/publications/publication.model';

@Component({
  selector: 'pnx-associated-publication-card-list',
  templateUrl: './associated-publications-card-list.component.html',
  styleUrls: ['../association-list.scss'],
})
export class AssociatedPublicationsCardListComponent {
  @Input() publications!: Publication[];
  @Input() association!: Association;
  @Input() elementId!: number;

  onPublicationDisassociated(): void {
    location.reload();
  }
}
