import { Component } from '@angular/core';
import { HomeDiscussionsTableComponent } from './home-discussions-table/home-discussions-table.component';
import { HomeDiscussionsToggleComponent } from './home-discussions-toggle/home-discussions-toggle.component';

@Component({
  standalone: true,
  selector: 'pnx-home-discussions',
  templateUrl: './home-discussions.component.html',
  styleUrls: ['./home-discussions.component.scss'],
  imports: [HomeDiscussionsTableComponent, HomeDiscussionsToggleComponent],
})
export class HomeDiscussionsComponent {
  myReportsOnly = HomeDiscussionsTableComponent.DEFAULT_MY_REPORTS_ONLY;
  toggleMyReports(isMyReports: boolean) {
    this.myReportsOnly = isMyReports;
  }
}
