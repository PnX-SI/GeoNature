import { Component, Input } from '@angular/core';

@Component({
  selector: 'pnx-loadable-layout',
  templateUrl: 'loadable-layout.component.html',
  styleUrls: ['loadable-layout.component.scss'],
})
export class LoadableLayoutComponent {
  @Input()
  isLoading: boolean = false;
}
