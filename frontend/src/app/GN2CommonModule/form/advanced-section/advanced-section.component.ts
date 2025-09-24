import { AfterViewChecked, Component, Input, OnInit } from '@angular/core';
import { animate, state, style, transition, trigger } from '@angular/animations';

export enum AdvancedSectionState {
  COLLAPSED = 'collapsed',
  EXPANDED = 'expanded',
}

@Component({
  selector: 'gn-advanced-section',
  templateUrl: 'advanced-section.component.html',
  styleUrls: ['./advanced-section.component.css'],
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
export class AdvancedSectionComponent implements AfterViewChecked {
  @Input()
  state: AdvancedSectionState = AdvancedSectionState.COLLAPSED;

  hideParent: boolean = false;
  advancedPanelID: string = 'advancedSection-' + window.crypto.randomUUID().slice(0, 5);

  ngAfterViewChecked() {
    // Hide the Advanced button if no forms (or anything else) in the advanced section
    this.hideParent = document.getElementById(this.advancedPanelID)?.childElementCount < 1;
  }

  toggleState() {
    this.state =
      this.state === AdvancedSectionState.COLLAPSED
        ? AdvancedSectionState.EXPANDED
        : AdvancedSectionState.COLLAPSED;
  }
}
