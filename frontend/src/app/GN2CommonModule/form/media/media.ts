class Media {

  public id_media:number;
  public id_table_location: number;
  public uuid_attached_row: string;
  public unique_id_media: string;
  public title_fr: string;
  public description_fr: string;
  public media_url: string;
  public media_path: string;
  public id_nomenclature_media_type: number;

  constructor(values={}) {
    this.setValues(values)
  }

  setValues(values: Object) {
    for (const key of Object.keys(values)) {
        this[key] = values[key];
    }
  }

}

export { Media }
