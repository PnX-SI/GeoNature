import { Component, OnInit, ViewChild, OnDestroy, Input } from '@angular/core';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { ConfigService } from '@geonature/services/config.service';
import { DatatableComponent } from '@swimlane/ngx-datatable';
import { DatePipe } from '@angular/common';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

@Component({
  selector: 'pnx-home-discussions',
  templateUrl: './home-discussions.component.html',
  styleUrls: ['./home-discussions.component.scss'],
  providers: [DatePipe],
})
export class HomeDiscussionsComponent implements OnInit, OnDestroy {
  @ViewChild('table') table: DatatableComponent;

  discussions = [];
  columns = [];
  currentPage = 1;
  perPage = 2;
  totalPages = 1;
  totalRows = 0;
  myReportsOnly = false;
  sort = 'desc';
  orderby = 'date';
  private destroy$ = new Subject<void>();

  constructor(
    private syntheseApi: SyntheseDataService,
    public config: ConfigService,
    private datePipe: DatePipe
  ) {}

  ngOnInit() {
    this.getDiscussions();
    console.log("INITIAL DISCUSSIONS", this.discussions);
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  getDiscussions() {
    const params = this.buildQueryParams();
    this.syntheseApi.getReports(params.toString())
      .pipe(takeUntil(this.destroy$))
      .subscribe(response => {
        this.setDiscussions(response);
      });
  }

  buildQueryParams(): URLSearchParams {
    const params = new URLSearchParams();
    params.set('type', 'discussion');
    params.set('sort', this.sort);
    params.set('page', this.currentPage.toString());
    params.set('per_page', this.perPage.toString());
    params.set('my_reports', this.myReportsOnly.toString());
    return params;
  }

  setDiscussions(data: any) {
    this.discussions = this.transformDiscussions(data.items);
    this.columns = this.getColumnsConfig();
    this.totalRows = data.total || 0;
    this.totalPages = data.pages || 1;
  }

  transformDiscussions(items: any[]): any[] {
    return items.map(item => ({
      ...item,
      observation: this.formatObservation(item.synthese),
    }));
  }

  getColumnsConfig() {
    return [
      { prop: 'creation_date', name: 'Date commentaire', sortable: true },
      { prop: 'user.nom_complet', name: 'Auteur', sortable: true },
      { prop: 'content', name: 'Contenu', sortable: true },
      { prop: 'observation', name: 'Observation', sortable: false, maxWidth: 500 },
    ];
  }

  formatObservation(synthese: any): string {
    return `
      <strong>Nom Cité:</strong> ${synthese.nom_cite || 'N/A'}<br>
      <strong>Observateurs:</strong> ${synthese.observers || 'N/A'}<br>
      <strong>Date Observation:</strong> ${
        this.formatDateRange(synthese.date_min, synthese.date_max) || 'N/A'
      }
    `;
  }

  toggleMyReports() {
    this.currentPage = 1;
    this.getDiscussions();
  }
  // TODO: déplacer le méthodes qui sont liées au composant table dans ce dernier et ajouter en input la fonction getDiscussions
  onRowClick(event: any) {
    // TODO: à pointer vers la route /synthese/occurence/:id_synthese/tab_discussion
    console.log('Clicked row:', event.row);
  }

  handlePageChange(event: any) {
    this.currentPage = event.page;
    this.getDiscussions();
  }

  onColumnSort(event: any) {
    this.sort = event.sorts[0].dir;
    this.orderby = event.sorts[0].prop;
    this.getDiscussions();
  }

  formatDateRange(dateMin: string, dateMax: string): string {
    if (!dateMin) return 'N/A';

    const formattedDateMin = this.datePipe.transform(dateMin, 'dd-MM-yyyy');
    const formattedDateMax = this.datePipe.transform(dateMax, 'dd-MM-yyyy');

    if (!dateMax || formattedDateMin === formattedDateMax) {
      return formattedDateMin || 'N/A';
    }

    return `${formattedDateMin} - ${formattedDateMax}`;
  }
}
