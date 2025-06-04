import { Component } from '@angular/core';
import { NgbCollapse } from '@ng-bootstrap/ng-bootstrap';
@Component({
  standalone: true,
  selector: 'pnx-module-layout',
  templateUrl: 'module-layout.component.html',
  styleUrls: ['module-layout.component.scss'],
  imports: [NgbCollapse],
})
export class ModuleLayoutComponent {
  public collapseFilters = false;
  public collapseList = false;
}
