import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GN2CommonModule } from '../GN2Common/GN2Common.module';
import { ExportsComponent } from './exports.component';
import { ExportsService } from './exports.service';
import { Routes, RouterModule } from '@angular/router';
import { TranslateModule, TranslateLoader} from '@ngx-translate/core';

const routes: Routes = [
  { path: '', component: ExportsComponent }
];


@NgModule({
  imports: [
    CommonModule,
    GN2CommonModule,
    RouterModule.forChild(routes),
    TranslateModule.forChild()
  ],
  exports: [],
  declarations: [ExportsComponent],
  providers: [ExportsService],
})
export class ExportsModule { }
