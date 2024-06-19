Cypress.Commands.add('getURLStepImport', (destination_label, id_import) => {
    const baseUrl = Cypress.env('urlApplication');
    return {
        "step_1_upload": {
            "url": `${baseUrl}/#/import/${destination_label}/process/upload`,
        },
        "step_2_decode_file": {
            "url": `${baseUrl}/#/import/${destination_label}/process/${id_import}/decode`,
        },
        "step_3_fieldmapping": {
            "url": `${baseUrl}/#/import/${destination_label}/process/${id_import}/fieldmapping`,
        },
        "step_4_contentmapping": {
            "url": `${baseUrl}/#/import/${destination_label}/process/${id_import}/contentmapping`,
        },
        "step_5_import_data": {
            "url": `${baseUrl}/#/import/${destination_label}/process/${id_import}/import`,
        }
    };
});