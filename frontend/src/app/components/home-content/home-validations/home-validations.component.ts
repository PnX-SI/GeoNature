import { Component } from '@angular/core';
import { HomeValidationsTableComponent } from './home-validations-table/home-validations-table.component';
import { HomeValidationsToggleComponent } from './home-validations-toggle/home-validations-toggle.component';

@Component({
  standalone: true,
  selector: 'pnx-home-validations',
  templateUrl: './home-validations.component.html',
  styleUrls: ['./home-validations.component.scss'],
  imports: [HomeValidationsTableComponent, HomeValidationsToggleComponent],
})
export class HomeValidationsComponent {
  // myReportsOnly = false;
  // toggleMyReports(isMyReports: boolean) {
  //   this.myReportsOnly = isMyReports;
  // }
}
