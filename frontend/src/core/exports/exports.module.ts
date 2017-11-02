import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { GN2CommonModule } from '../GN2Common/GN2Common.module';
import { ExportsComponent } from './exports.component';
import { ExportsService } from './exports.service';

@NgModule({
  imports: [
    BrowserModule,
    GN2CommonModule,
  ],
  exports: [ExportsComponent],
  declarations: [ExportsComponent],
  providers: [ExportsService],
})
export class ExportsModule { }
