import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { ExportsComponent } from './exports.component';
import { ExportsService } from './exports.service';
import { Routes, RouterModule } from '@angular/router';
import { HttpClientModule, HttpClientXsrfModule, HTTP_INTERCEPTORS } from '@angular/common/http';
const routes: Routes = [
  { path: '', component: ExportsComponent }
];


@NgModule({
  imports: [
    HttpClientXsrfModule.withOptions({
      cookieName: 'token',
      headerName: 'token'
    }),
    CommonModule,
    GN2CommonModule,
    RouterModule.forChild(routes),
  ],
  exports: [],
  declarations: [ExportsComponent],
  providers: [ExportsService],
})
export class ExportsModule { }
