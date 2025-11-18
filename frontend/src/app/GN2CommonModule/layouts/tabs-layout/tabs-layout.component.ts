import { Component, Input } from '@angular/core';
import { ChildRouteDescription } from '@geonature/routing/childRouteDescription';

@Component({
  selector: 'gn-tabs-layout',
  templateUrl: 'tabs-layout.component.html',
  styleUrls: ['tabs-layout.component.scss'],
})
export class TabsLayoutComponent {
  @Input()
  tabs: Array<ChildRouteDescription> = [];
}
