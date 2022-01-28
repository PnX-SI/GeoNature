import { Injectable } from '@angular/core';
import { ModuleService } from "@geonature/services/module.service"

@Injectable({providedIn: 'root'})
export class NavHomeService {
    public moduleName: string;
    public currentDocUrl: string;
    constructor(private moduleService: ModuleService) { 
        this.onModuleChange()
    }
    
    private onModuleChange() {
        this.moduleService.currentModule$.subscribe(module => {    
            if (module) {
              this.moduleName = module.module_label;
              if (module.module_doc_url) {
                this.currentDocUrl = module.module_doc_url;
              }
              // set theme
              const appRoot = document.getElementById("app-root");
              appRoot.className = "";
              appRoot.classList.add(module.theme);

            } else {
              this.moduleName = 'Accueil';
            }
          })
      }
    
}