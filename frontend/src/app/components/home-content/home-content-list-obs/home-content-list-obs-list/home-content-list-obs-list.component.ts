import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';

interface HomeContentListObservationItem {
  id_synthese: number;
  nom_vern_or_lb_nom: string;
  date_min: string | null;
  observers: string | null;
}

@Component({
  standalone: true,
  selector: 'pnx-home-content-list-obs-list',
  templateUrl: './home-content-list-obs-list.component.html',
  styleUrls: ['./home-content-list-obs-list.component.scss'],
  imports: [GN2CommonModule, CommonModule],
})
export class HomeContentListObsListComponent {
  @Input() observations: HomeContentListObservationItem[] = [];
  @Input() isLoading = false;

  renderDate(date: string | null): string {
    return date ? new Date(date).toLocaleDateString() : '';
  }
}
