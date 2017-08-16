import { Injectable, OnInit } from '@angular/core';
import { Subject } from 'rxjs/Subject';
import {MdSidenavModule, MdSidenav} from '@angular/material';

@Injectable()
export class NavService {
    sidenav: MdSidenav;
    constructor() {}
    setAppSideNav(sidenav) {
        sidenav.mode = 'over';
        sidenav.opened = false;
    }
    setAccueil(sidenav) {
        sidenav.mode = 'side';
        sidenav.opened = true;
    }
}
