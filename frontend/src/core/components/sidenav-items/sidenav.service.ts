import { Injectable } from '@angular/core';
import {MatSidenavModule, MatSidenav} from '@angular/material/sidenav';

@Injectable()
export class SideNavService {
    sidenav: MatSidenav;
    opened: boolean;
    constructor() {
        this.opened = false;
    }
    setSideNav(sidenav) {
        this.sidenav = sidenav;
    }
    setModule(sidenav: MatSidenav) {
        sidenav.close();
    }
    setHome(sidenav: MatSidenav) {
        sidenav.open();
    }
}
