import { Component, Input } from '@angular/core';

export enum LoadableLayoutMode {
  Overlay = 'overlay',
  Replace = 'replace',
}

@Component({
  selector: 'gn-loadable-layout',
  templateUrl: 'loadable-layout.component.html',
  styleUrls: ['loadable-layout.component.scss'],
})
export class LoadableLayoutComponent {
  readonly LoadableLayoutMode = LoadableLayoutMode;

  @Input()
  isLoading: boolean = false;
  @Input()
  message: string = null;
  @Input()
  mode: LoadableLayoutMode = LoadableLayoutMode.Overlay;
}
