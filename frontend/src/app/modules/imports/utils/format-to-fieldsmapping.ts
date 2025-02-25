import { FieldMappingValues } from '../models/mapping.model';

export function formatQueryParams(queryParams: { [key: string]: string }): FieldMappingValues {
  const formattedParams: FieldMappingValues = {};

  Object.keys(queryParams).forEach((key) => {
    const value = queryParams[key];

    const parsedValue = !isNaN(Number(value)) ? Number(value) : value;

    formattedParams[key] = {
      column_src: '',
      default_value: parsedValue,
    };
  });

  return formattedParams;
}
