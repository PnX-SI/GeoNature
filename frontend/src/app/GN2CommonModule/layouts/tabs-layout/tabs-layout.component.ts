import { Component, Input } from '@angular/core';

export interface TabDescription {
  label: string;
  path: string;
  configEnabledField?: string;
  component: any;
}

@Component({
  selector: 'pnx-tabs-layout',
  templateUrl: 'tabs-layout.component.html',
  styleUrls: ['tabs-layout.component.scss'],
})
export class TabsLayoutComponent {
  @Input()
  tabs: Array<TabDescription> = [];
}
