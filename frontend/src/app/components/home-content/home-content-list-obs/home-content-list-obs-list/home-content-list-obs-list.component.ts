import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { ConfigService } from '@geonature/services/config.service';

interface HomeContentListObservationItem {
  id_synthese: number;
  nom_vern_or_lb_nom: string;
  date_min: string | null;
  observers: string | null;
  [key: string]: string | number | null;
}

interface HomeContentListObservationColumn {
  name: string;
  prop: string;
}

@Component({
  standalone: true,
  selector: 'pnx-home-content-list-obs-list',
  templateUrl: './home-content-list-obs-list.component.html',
  styleUrls: ['./home-content-list-obs-list.component.scss'],
  imports: [GN2CommonModule, CommonModule],
})
export class HomeContentListObsListComponent {
  readonly pageSize = 9;

  @Input() observations: HomeContentListObservationItem[] = [];
  @Input() isLoading = false;

  constructor(private readonly config: ConfigService) {}

  get columns(): HomeContentListObservationColumn[] {
    const configuredColumns = this.config.FRONTEND?.LIST_LAST_OBS_CONFIG?.COLUMNS;
    return Array.isArray(configuredColumns) ? configuredColumns : [];
  }

  getCellValue(row: HomeContentListObservationItem, prop: string): string | number {
    if (prop === 'date_min') {
      return this.renderDate(row.date_min);
    }

    return row[prop] ?? '';
  }

  renderDate(date: string | null): string {
    return date ? new Date(date).toLocaleDateString() : '';
  }
}
