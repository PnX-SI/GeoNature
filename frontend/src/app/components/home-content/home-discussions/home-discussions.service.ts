import { Injectable } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';
import { ModuleService } from '@geonature/services/module.service';

enum DiscussionsModule {
  SYNTHESE = 'SYNTHESE',
  VALIDATION = 'VALIDATION',
}

@Injectable()
export class HomeDiscussionsService {
  readonly MODULES_PREVALENCE = [DiscussionsModule.SYNTHESE, DiscussionsModule.VALIDATION];
  constructor(
    private _config: ConfigService,
    private _moduleService: ModuleService
  ) {}

  private _isReadGrantedInModule(module: DiscussionsModule): boolean {
    return this._moduleService.getModule(module)?.cruved['R'] != undefined;
  }
  private _isDiscussionsAvailableInModule(module: DiscussionsModule): boolean {
    return this._config.SYNTHESE.DISCUSSION_MODULES.includes(module);
  }

  private _getUrl(module: DiscussionsModule, id: number): Array<string> {
    switch (module) {
      case DiscussionsModule.SYNTHESE:
        return ['/synthese', 'occurrence', id.toString(), 'discussion'];
      case DiscussionsModule.VALIDATION:
        return ['/validation', 'occurrence', id.toString(), 'discussion'];
    }
  }

  get isAvailable(): boolean {
    if (!this._config.HOME.DISPLAY_LATEST_DISCUSSIONS) {
      return false;
    }

    return this.MODULES_PREVALENCE.some(module =>
      this._isReadGrantedInModule(module) && this._isDiscussionsAvailableInModule(module)
    )
  }

  computeDiscussionsRedirectionUrl(id: number): Array<string> {
    for (const module of this.MODULES_PREVALENCE) {
      if (this._isReadGrantedInModule(module)) {
        if (this._isDiscussionsAvailableInModule(module)) {
          return this._getUrl(module, id);
        }
      }
    }
    return [];
  }
}
