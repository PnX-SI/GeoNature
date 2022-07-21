import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { MatIconModule } from '@angular/material/icon';

import { GNPanelComponent } from './gn-panel.component';

@NgModule({
  imports: [CommonModule, MatIconModule],
  declarations: [GNPanelComponent],
  exports: [GNPanelComponent],
})
export class GNPanelModule {}
