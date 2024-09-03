import { Component, OnInit, ViewChild, OnDestroy, Input } from '@angular/core';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { ConfigService } from '@geonature/services/config.service';
import { DatatableComponent } from '@swimlane/ngx-datatable';
import { DatePipe } from '@angular/common';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { HomeDiscussionsTableComponent } from './home-discussions-table/home-discussions-table.component';
import { HomeDiscussionsToggleComponent } from './home-discussions-toggle/home-discussions-toggle.component';

@Component({
  standalone: true,
  selector: 'pnx-home-discussions',
  templateUrl: './home-discussions.component.html',
  styleUrls: ['./home-discussions.component.scss'],
  providers: [DatePipe],
  imports: [HomeDiscussionsTableComponent, HomeDiscussionsToggleComponent],
})
export class HomeDiscussionsComponent implements OnInit, OnDestroy {
  @ViewChild('table') table: DatatableComponent;

  discussions = [];
  currentPage = 1;
  perPage = 2;
  totalPages = 1;
  totalRows = 0;
  totalFilteredRows = 0;
  myReportsOnly = false;
  sort = 'desc';
  orderby = 'creation_date';
  private destroy$ = new Subject<void>();

  constructor(
    private syntheseApi: SyntheseDataService,
    public config: ConfigService,
    private datePipe: DatePipe
  ) {}

  async ngOnInit() {
    this.getDiscussions();
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  getDiscussions() {
    const params = this.buildQueryParams();
    this.syntheseApi
      .getReports(params.toString())
      .pipe(takeUntil(this.destroy$))
      .subscribe((response) => {
        this.setDiscussions(response);
      });
  }

  buildQueryParams(): URLSearchParams {
    const params = new URLSearchParams();
    params.set('type', 'discussion');
    params.set('sort', this.sort);
    params.set('orderby', this.orderby);
    params.set('page', this.currentPage.toString());
    params.set('per_page', this.perPage.toString());
    params.set('my_reports', this.myReportsOnly.toString());
    return params;
  }

  setDiscussions(data: any) {
    this.discussions = this.transformDiscussions(data.items);
    this.totalRows = data.total;
    this.totalPages = data.pages;
    this.totalFilteredRows = data.total_filtered;
  }

  transformDiscussions(items: any[]): any[] {
    return items.map((item) => ({
      ...item,
      observation: this.formatObservation(item.synthese),
    }));
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

  toggleMyReports(isMyReports: boolean) {
    this.myReportsOnly = isMyReports;
    this.currentPage = 1;
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

  // Event handlers for updates from the child component
  // NOTES: utilisation de service à la place ?
  onSortChange(sortAndOrberby: { sort: string; orderby: string }) {
    this.sort = sortAndOrberby.sort;
    this.orderby = sortAndOrberby.orderby;
    this.getDiscussions();
  }

  onCurrentPageChange(newPage: number) {
    this.currentPage = newPage;
    this.getDiscussions();
  }
}
