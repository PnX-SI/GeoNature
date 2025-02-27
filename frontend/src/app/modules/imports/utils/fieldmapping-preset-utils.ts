import { FieldMappingItem, FieldMappingValues } from '../models/mapping.model';

export class FieldMappingPresetUtils {
  static readonly PRESET_KEY = '__preset__';

  static formatQueryParamsToFieldMapping(queryParams: {
    [key: string]: string;
  }): FieldMappingValues | null {
    const formattedParams: Record<string, FieldMappingItem> = {};

    Object.keys(queryParams).forEach((key) => {
      const value = queryParams[key];

      const parsedValue = !isNaN(Number(value)) ? Number(value) : value;

      formattedParams[key] = {
        column_src: '',
        default_value: parsedValue,
      };
    });

    return {
      [FieldMappingPresetUtils.PRESET_KEY]: formattedParams,
    };
  }

  /**
   * Apply preset if exists
   */
  static patchMappingValuesWithPreset(
    mappingValues: FieldMappingValues,
    preset: FieldMappingValues | null
  ): FieldMappingValues {
    // Replace input mapping entries if a preset is set in "importFieldMapping"
    const presetValues = preset?.__preset__;
    if (presetValues) {
      for (const presetKey in presetValues) {
        mappingValues[presetKey] = preset[presetKey];
      }
    }
    return mappingValues;
  }
}
