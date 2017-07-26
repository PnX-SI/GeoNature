import { Component, OnInit } from '@angular/core';
import { NavService } from '../../services/nav.service';

@Component({
  selector: 'app-sidenav-items',
  templateUrl: './sidenav-items.component.html',
  styleUrls: ['./sidenav-items.component.scss']
})
export class SidenavItemsComponent implements OnInit {

  public nav = [{}];

  constructor(private _navService: NavService) {
    this.nav = _navService.getAppList();
  }
  ngOnInit() {
  }
  onSetApp(appName: string) {
    this._navService.setAppName(appName);
  }
}
