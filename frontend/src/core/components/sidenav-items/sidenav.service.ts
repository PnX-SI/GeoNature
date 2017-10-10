import { Injectable } from '@angular/core';
import {MdSidenavModule, MdSidenav} from '@angular/material';

@Injectable()
export class SideNavService {
    sidenav: MdSidenav;
    opened: boolean;
    constructor() {
        this.opened = false;
    }
    setSideNav(sidenav){
        this.sidenav = sidenav;
    }
    setModule(sidenav: MdSidenav) {
        sidenav.close()
    }
    setHome(sidenav: MdSidenav) {
        sidenav.open()
    }
}
