import { Component, OnInit } from '@angular/core';
import { NavService } from '../../services/nav.service';

@Component({
  selector: 'app-sidenav-items',
  templateUrl: './sidenav-items.component.html',
  styleUrls: ['./sidenav-items.component.scss']
})
export class SidenavItemsComponent implements OnInit {

  private geonature_image;
  public nav = [{}];

  constructor(private _navService: NavService) {
    this.nav = _navService.getAppList();
  }
  ngOnInit() {
      this.geonature_image = './../../../images/geonature_image3.png';
  }
  onSetApp(appName: string) {
    this._navService.setAppName(appName);
  }
}
