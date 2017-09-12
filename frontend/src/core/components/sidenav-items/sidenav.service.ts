import { Injectable } from '@angular/core';
import {MdSidenavModule, MdSidenav} from '@angular/material';

@Injectable()
export class SideNavService {
    sidenav: MdSidenav;
    constructor() {}
    setSideNav(sidenav){
        this.sidenav = sidenav;
    }
    setAppSideNav(sidenav) {
        sidenav.mode = 'over';
        sidenav.opened = false;
    }
    setHome(sidenav) {
        sidenav.mode = 'side';
        sidenav.opened = true;
    }
}
