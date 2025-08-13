import {Component, OnInit} from '@angular/core';
import {ConfigService} from '@geonature/services/config.service';
import {ModuleService} from '../../services/module.service';
import {SideNavService} from './sidenav-service';
import {UtilsService} from "@geonature/services/utils.service";

@Component({
  selector: 'pnx-sidenav-items',
  templateUrl: './sidenav-items.component.html',
  styleUrls: ['./sidenav-items.component.scss'],
})
export class SidenavItemsComponent implements OnInit {
  public nav = [{}];
  public version = null;
  public home_page: any;
  public refTooltip: string | null = null;
  private isRefVersionLoaded = false; // Pour éviter plusieurs appels


  constructor(
    public moduleService: ModuleService,
    public _sidenavService: SideNavService,
    public utilsService: UtilsService,
    public config: ConfigService,
  ) {
    this.version = this.config.GEONATURE_VERSION;
  }

  ngOnInit() {
    this.home_page = this._sidenavService.getHomeItem();
  }

  setHome() {
    this.moduleService.currentModule$.next(null);
  }

  getModulesVersionTooltip(): string {
    return this.moduleService.getModules()
      ?.filter(m => m.version)
      ?.map(m => `${m.module_label}: ${m.version}`)
      ?.join('\n') || '';
  }

  onMenuOpened(): void {
    if (!this.isRefVersionLoaded) {
      this.utilsService.getRefVersion().subscribe({
        next: (data) => {
          this.refTooltip = Object.entries(data)
            .map(([key, value]) => `${key}: ${value}`)
            .join('\n');
          this.isRefVersionLoaded = true;
        },
      });
    }
  }
}
