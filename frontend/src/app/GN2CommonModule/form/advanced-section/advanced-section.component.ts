import { Component, Input } from '@angular/core';
import { animate, state, style, transition, trigger } from '@angular/animations';

export enum AdvancedSectionState {
  COLLAPSED = 'collapsed',
  EXPANDED = 'expanded',
}

@Component({
  selector: 'pnx-advanced-section',
  templateUrl: 'advanced-section.component.html',
  animations: [
    trigger('state', [
      state(
        AdvancedSectionState.COLLAPSED,
        style({
          height: '0px',
          minHeight: '0',
          margin: '-1px',
          overflow: 'hidden',
          padding: '0',
          display: 'none',
        })
      ),
      state(AdvancedSectionState.EXPANDED, style({ height: '*' })),
      transition(
        `${AdvancedSectionState.EXPANDED} <=> ${AdvancedSectionState.COLLAPSED}`,
        animate('250ms cubic-bezier(0.4, 0.0, 0.2, 1)')
      ),
    ]),
  ],
})
export class AdvancedSectionComponent {
  @Input()
  state: AdvancedSectionState = AdvancedSectionState.COLLAPSED;

  toggleState() {
    this.state =
      this.state === AdvancedSectionState.COLLAPSED
        ? AdvancedSectionState.EXPANDED
        : AdvancedSectionState.COLLAPSED;
  }
}
