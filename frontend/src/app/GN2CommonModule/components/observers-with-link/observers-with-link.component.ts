import { Component, Input } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'gn-observers-with-link',
  templateUrl: 'observers-with-link.component.html',
  styleUrls: ['observers-with-link.component.scss'],
})
export class ObserversWithLinkComponent {
  observersAsList: string[];
  observersAsText: string;

  @Input()
  target: string = '_self';

  @Input()
  set observers(observers: string) {
    this.observersAsText = observers;

    if (this.isObserverSheetEnabled) {
      this.observersAsList = observers
        .split(this._config.SYNTHESE.FIELD_OBSERVERS_SEPARATORS)
        .map((observer) => observer.trim())
        .filter((observer) => !!observer);
    }
    console.log(this.observersAsText);
    console.log(this.observersAsList);
  }

  constructor(private _config: ConfigService) {}

  get isObserverSheetEnabled(): boolean {
    return this._config.SYNTHESE.ENABLE_OBSERVER_SHEETS;
  }
}
