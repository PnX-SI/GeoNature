/**
 * @class application.editAp
 * Singleton to build the editAp window
 *
 * @singleton
 */

application.editStation = function() {
    // private variables

    /**
     * Property: map
     * {OpenLayers.Map}
     */
    map = null;

    /**
     * Property: toolbar
     * {mapfish.widgets.ToolBar}
     */
    var toolbar = null;

    /**
     * Property: toolbarInitializedOnce
     * {Boolean} toolbar has already been initialized
     */
    var toolbarInitializedOnce = false;

    /**
     * Property: vectorLayer
     * {OpenLayers.Layer.Vector}
     */
    vectorLayer = null;

    /**
     * Property: dragPanControl
     */
    var dragPanControl = null;

    /**
     * Property: dragPolygonControl
     */
    var dragPolygonControl = null;

    /**
     * Property: store
     * {Ext.data.Store} The ap store (should contain only one record)
     */
    var store = null;

    /**
     * Property: protocol
     * {mapfish.Protocol.MapFish}
     */
    var protocol = null

    /**
     * Property: eventProtocol
     * {mapfish.Protocol.TriggerEventDecorator}
     */
    var eventProtocol = null;

    /**
     * Property: filterProtocol
     * {mapfish.Protocol.MergeFilterDecorator}
     */
    var filterProtocol = null;

    /**
     * Property: format
     * {<OpenLayers.Format.WKT>}
     */
    var format = new OpenLayers.Format.WKT();

    /**
     * APIProperty: id_station
     * The id of station to update (if applies), null in case of a creating a new station
     */
    var id_station = null;
    
    /**
     * APIProperty: old_cd_nom
     * The old cd_nom of the taxon to update
     */
    var old_taxon = null;

    /**
     * Property: layerTreeTip
     * {Ext.Tip} The layerTreeTip created with the factory
     */
    var layerTreeTip = null;

    /**
     * Property: firstGeometryLoad
     * {Boolean} is the geometry has been load once only
     */
    var firstGeometryLoad = true;

    /**
     * Property: firstAltitudeLoad
     * {Boolean} is the altitude has been load once only
     */
    var firstAltitudeLoad = true;
    
    /**
     * Property: maProjection
     * {Openlayers.Projection} définie ici sinon temps de retard lors de la création du point gps ???
     */
    var maProjection = null;
    
    // private functions

    /**
     * Method: initViewport
     */
    var initWindow = function() {
        return new Ext.Window({
            title: "Modifier une station"
            ,layout: 'border'
            ,modal: true
            ,plain: true
            ,plugins: [new Ext.ux.plugins.ProportionalWindows()]
            //,aspect: true
            ,width: 600
            ,height: 350
            ,percentage: .95
            ,split: true
            ,closeAction: 'hide'
            ,defaults: {
                border: false
            }
            // ,bbar: new Ext.StatusBar({
                // id: 'edit-station-status'
                // ,defaultText: ''
            // })
            ,items: [
                getWindowCenterItem()
                ,getViewportEastItem()
            ]
            ,listeners: {
                show: initToolbarItems
                ,hide: resetWindow
                ,afterlayout: function(){
                  map.baseLayer.redraw();
                }
            }
        });
    };

    /**
     * Method: getViewportNorthItem
     */
    var getViewportEastItem = function() {
        return {
            region: 'east'
            ,width: 500
            ,split: true
            ,autoScroll: true
            ,defaults: {
                border: false
            }
            ,items: [{
                id: 'edit-station-form'
                ,xtype: 'form'
                ,bodyStyle: 'padding: 5px'
                ,disabled: true
                ,defaults: {
                    xtype: 'numberfield'
                    ,labelWidth: 90
                    ,width: 180
                    ,anchor:'-15'
                }
                ,labelAlign: 'left'
                ,monitorValid:true
                // ,items: [getFormItems()]
                ,items: [getFormItems(),getFormTaxons()]
                //pour version Extjs 3.4.0
                ,buttons:[{
                    text: 'Annuler'
                    ,xtype: 'button'
                    ,handler: function() {
                        application.editStation.window.hide();
                    }
                    ,scope: this
                },{
                    text: 'Enregistrer'
                    ,xtype: 'button'
                    ,id: 'stationSaveButton'
                    ,iconCls: 'action-save'
                    ,handler:submitForm
                }]
            }]
        }
    };

    /**
     * Method: getViewportCenterItem
     */
    var getWindowCenterItem = function() {
        createMap();
        toolbar = new mapfish.widgets.toolbar.Toolbar({
            map: map,
            configurable: false
        });

        return {
            region: 'center'
            ,id: 'edit-station-mapcomponent'
            ,xtype: 'mapcomponent'
            ,map: map
            ,tbar: toolbar
        };
    };

    /**
     * Method: getFormItems
     * Creates the form items
     */
    var getFormItems = function() { 
        var comboObservateurs = new Ext.ux.form.SuperBoxSelect({
            id:'combo-station-observateurs'
            ,xtype:'superboxselect'
            ,fieldLabel: 'Observateur(s) ' 
            ,name: 'lesobservateurs'
            ,store: application.auteurStore
            ,displayField: 'auteur'
            ,valueField: 'id_role'
            ,allowBlank: false
            ,resizable: true
            ,forceSelection : true
            ,selectOnFocus:true
            ,resizable: true
            ,mode: 'local'
            ,value:''
            ,updateIdsObservateurs:function(){Ext.getCmp('edit-station-form').getForm().findField('ids_observateurs').setValue(this.getValue());}
            ,listeners:{
                afterrender :function(){
                    Ext.getCmp('edit-station-form').getForm().findField('ids_observateurs').setValue(this.getValue());
                }
                ,additem:function(){
                    this.updateIdsObservateurs();
                }
                ,removeitem:function(){
                    this.updateIdsObservateurs();
                }
                ,clear:function(){
                    this.updateIdsObservateurs();
                } 
                ,render: function(c) {
                    Ext.QuickTips.register({
                        target: c.getEl(),
                        text: 'Le ou les auteurs du relevé de la station.'
                    });
                }
            }
        });
        return [{
            id:'hidden-idstation'
            ,xtype:'hidden'
            ,name: 'id_station'   
        },{
            xtype:'hidden'
            ,name: 'monaction'
        },{
            xtype: 'hidden'
            ,name: 'geometry' 
        },{
            xtype:'hidden'
            ,name: 'ids_observateurs'
        },{
            id: 'labelstation-station'
            ,xtype:'label'
            ,html: ''
        },{
        // Fieldset 
        xtype:'fieldset'
        ,id:'fieldset-1-station'
        ,columnWidth: 1
        ,title: 'Etape 1'
        ,collapsible: true
        ,autoHeight:true
        ,anchor:'98%'
        //,defaults: {anchor: '-20' // leave room for error icon}
        // ,defaultType: 'textfield'
        ,items :[comboObservateurs
            ,{
                id:'datefield-station-date'
                ,fieldLabel: 'Date '
                ,name: 'dateobs'
                ,xtype:'datefield'
                ,maxValue: new Date()
                ,format: 'd/m/Y'
                ,altFormats:'Y-m-d'
                ,allowBlank: false
                ,blankText:'La date du relevé est obligatoire'
                ,listeners: {
                    render: function(c) {
                        Ext.QuickTips.register({
                            target: c.getEl(),
                            text: 'Date de réalisation du relevé. Elle ne peut donc être postérieure à la date de saisie.'
                        });
                    }
                }
            },{
                id:'textfield-station-acces'
                ,xtype: 'textarea'
                ,fieldLabel: 'Accès '
                ,name: 'info_acces'
                ,anchor:'90%'
                // ,width:250
                ,listeners: {
                    render: function(c) {
                        Ext.QuickTips.register({
                            target: c.getEl(),
                            text: 'Information facultative concernant la façon d\'accéder à la station relevée.'
                        });
                    }
                }
            },{
                id:'combo-station-support'
                ,xtype:"twintriggercombo"
                ,fieldLabel: 'Pointage sur '
                ,name: 'support'
                ,hiddenName:"id_support"
                ,store: application.supportStore
                ,valueField: "id_support"
                ,displayField: "nom_support"
                ,typeAhead: true
                ,forceSelection: true
                ,selectOnFocus: true
                ,editable: true
                ,allowBlank: false
                ,blankText:'Le support ayant servi à la localisation doit être renseigné'
                ,triggerAction: 'all'
                ,trigger3Class: 'x-form-zoomto-trigger x-hidden'
                ,mode: 'local'
            },{
                id:'textfield-station-pdop'
                ,xtype: 'numberfield'
                ,fieldLabel: 'Pdop '
                ,name: 'pdop'
                ,anchor:'40%'
                ,allowDecimals :true
                ,allowNegative: false
                ,decimalPrecision: 1
                ,decimalSeparator: '.'
                ,nanText:'Ceci n\'est pas un nombre valide.'
                ,listeners: {
                    render: function(c) {
                        Ext.QuickTips.register({
                            target: c.getEl(),
                            text: 'Information facultative concernant le pdop du GPS s\'il a été utilisé.'
                        });
                    }
                }
            },{
                xtype: 'radiogroup'
                ,fieldLabel: 'Surface '
                ,anchor    : '90%'
                ,items: [
                    {boxLabel: '100 m2', name: 'id_surface', inputValue: 1, checked:true}
                    ,{boxLabel: '10 m2', name: 'id_surface', inputValue: 2}
                    // ,{boxLabel: 'Pas d\'information', name: 'id_surface', inputValue: 999}

                ]
             },{
                id:'combo-station-exposition'
                ,xtype:"twintriggercombo"
                ,fieldLabel: 'Exposition '
                ,name: 'exposition'
                ,hiddenName:"id_exposition"
                ,store: application.expositionStore
                ,valueField: "id_exposition"
                ,displayField: "nom_exposition"
                ,allowBlank:false
                ,typeAhead: true
                ,forceSelection: true
                ,selectOnFocus: true
                ,editable: true
                ,triggerAction: 'all'
                ,trigger3Class: 'x-form-zoomto-trigger x-hidden'
                ,mode: 'local'
            }
            ,{
                id: 'numberfield-altitude'
                ,xtype:'numberfield'
                ,fieldLabel: 'Altitude '
                ,allowDecimals :false
                ,allowNegative: false
                ,name: 'altitude'
                ,anchor: '40%'
                ,listeners: {
                    render: function(c) {
                        Ext.QuickTips.register({
                            target: c.getEl(),
                            text: 'L\'altitude est calculée à partir d\'un service de l\'API Geoportail de l\'IGN. Vous pouvez la corriger si vous le souhaitez.'
                        });
                    }
                }
            }]
        } //fin du groupe 1
        ,{ //groupe 2
            xtype:'fieldset'
            ,id:'fieldset-2-station'
            ,columnWidth: 1
            ,title: 'Etape 2'
            ,collapsible: true
            ,autoHeight:true
            ,anchor:'98%'
            //,defaults: {anchor: '-20' // leave room for error icon}
            // ,defaultType: 'textfield'
            ,items :[{
                xtype: 'radiogroup'
                ,fieldLabel: 'Relevé '
                ,anchor    : '90%'
                ,items: [
                    {boxLabel: 'Complet', name: 'releve', inputValue: 'C', checked: true}
                    ,{boxLabel: 'Partiel', name: 'releve', inputValue: 'P'}
                ]
                ,listeners:{
                    select:function(){
                        if(this.getValue()==101){
                            Ext.getCmp('textfield-station-sophie').showItem();  
                            Ext.getCmp('textfield-station-sophie').show();
                            
                        }
                        else{
                            Ext.getCmp('textfield-station-sophie').setValue(0);
                            Ext.getCmp('textfield-station-sophie').hideItem();
                            Ext.getCmp('textfield-station-sophie').hide();
                        }
                    }
                    ,render: function(c) {
                        Ext.QuickTips.register({
                            target: c.getEl(),
                            text: 'Choisir un programme dans le cadre duquel ce relevé a été fait - (facultatif)'
                        });
                    } 
                }
            }]
        }  //fin du groupe 2
        ,{ //groupe 3
            xtype:'fieldset'
            ,id:'fieldset-3-station'
            ,columnWidth: 1
            ,title: 'Etape 3'
            ,collapsible: true
            ,autoHeight:true
            ,anchor:'98%'
            ,defaults: {anchor: '-20'} // leave room for error icon
            ,defaultType: 'numberfield'
            ,items :[{
                id:'combo-station-programme'
                ,xtype:"twintriggercombo"
                ,fieldLabel: 'Programme '
                ,name: 'programme'
                ,hiddenName:"id_programme_fs"
                ,store: application.programmeStore
                ,valueField: "id_programme_fs"
                ,displayField: "nom_programme_fs"
                ,allowBlank:false
                ,typeAhead: true
                ,forceSelection: true
                ,selectOnFocus: true
                ,editable: true
                ,triggerAction: 'all'
                ,trigger3Class: 'x-form-zoomto-trigger x-hidden'
                ,mode: 'local'
                ,value:999
                ,listeners:{
                    select:function(){
                        if(this.getValue()==101){
                            Ext.getCmp('textfield-station-sophie').showItem();  
                            Ext.getCmp('textfield-station-sophie').show();
                            
                        }
                        else{
                            Ext.getCmp('textfield-station-sophie').setValue(0);
                            Ext.getCmp('textfield-station-sophie').hideItem();
                            Ext.getCmp('textfield-station-sophie').hide();
                        }
                    }
                    ,render: function(c) {
                        Ext.QuickTips.register({
                            target: c.getEl(),
                            text: 'Choisir un programme dans le cadre duquel ce relevé a été fait - (facultatif)'
                        });
                    } 
                }
            },{
                id:'textfield-station-sophie'
                ,xtype: 'textfield'
                ,fieldLabel: 'Id sophie '
                ,name: 'id_sophie'
                ,maxLength:5
                ,maxLengthText:'Un code sophie ne peut pas comporter plus de 5 caractères'
                ,anchor:'40%'
                ,listeners: {
                    render: function(c) {
                        Ext.QuickTips.register({
                            target: c.getEl(),
                            text: 'N° du polygone SOPHIE pour lequel ce relevé est réalisé. 5 caractères maximum.'
                        });
                    }
                }
            },{
                xtype: 'radiogroup'
                ,fieldLabel: 'Surface Homogène '
                ,anchor    : '90%'
                ,items: [
                    {boxLabel: 'Oui', name: 'id_homogene', inputValue: 1,}
                    ,{boxLabel: 'Non', name: 'id_homogene', inputValue: 2}
                    // ,{boxLabel: 'Ne sait pas', name: 'id_homogene', inputValue: 9}
                ]
            }
            ,{ //ssgroupe relief
                xtype:'fieldset'
                ,id:'fieldset-relief'
                ,columnWidth: 1
                ,title: 'Relief de la station'
                ,collapsible: false
                ,autoHeight:true
                ,anchor:'98%'
                ,defaults: {anchor: '-20'} // leave room for error icon
                ,items :[{
                    id:'combo-station-microrelief1'
                    ,fieldLabel: 'Micro-relief 1 '
                    ,name: 'microrelief1'
                    ,xtype:"twintriggercombo"
                    ,hiddenName:"id_microrelief1"
                    ,store: application.microreliefStore
                    ,valueField: "id_microrelief"
                    ,displayField: "nom_microrelief"
                    ,typeAhead: true
                    ,forceSelection: true
                    ,selectOnFocus: true
                    ,editable: true
                    ,resizable : true
                    ,triggerAction: 'all'
                    ,trigger3Class: 'x-form-zoomto-trigger x-hidden'
                    ,mode: 'local'
                },{
                    id:'combo-station-microrelief2'
                    ,fieldLabel: 'Micro-relief 2 '
                    ,name: 'microrelief2'
                    ,xtype:"twintriggercombo"
                    ,hiddenName:"id_microrelief2"
                    ,store: application.microreliefStore
                    ,valueField: "id_microrelief"
                    ,displayField: "nom_microrelief"
                    ,typeAhead: true
                    ,forceSelection: true
                    ,selectOnFocus: true
                    ,editable: true
                    ,resizable : true
                    ,triggerAction: 'all'
                    ,trigger3Class: 'x-form-zoomto-trigger x-hidden'
                    ,mode: 'local'
                },{
                    id:'combo-station-microrelief3'
                    ,fieldLabel: 'Micro-relief 3 '
                    ,name: 'microrelief3'
                    ,xtype:"twintriggercombo"
                    ,hiddenName:"id_microrelief3"
                    ,store: application.microreliefStore
                    ,valueField: "id_microrelief"
                    ,displayField: "nom_microrelief"
                    ,typeAhead: true
                    ,forceSelection: true
                    ,selectOnFocus: true
                    ,editable: true
                    ,resizable : true
                    ,triggerAction: 'all'
                    ,trigger3Class: 'x-form-zoomto-trigger x-hidden'
                    ,mode: 'local'
                },{
                    xtype: 'compositefield'
                    ,fieldLabel: 'Méso-relief '
                    ,msgTarget : 'side'
                    ,anchor    : '90%'
                    ,defaults: {
                        flex: 1
                        ,xtype: 'numberfield'
                        ,allowDecimals :false
                        ,allowNegative: false
                        ,minValue:1               
                    },
                    items: [{
                       xtype: 'displayfield'
                       ,value: 'amont-aval'
                    },{
                        id: 'fieldstation-meso_longitudinal'
                        ,name: 'meso_longitudinal'
                        ,width: 50
                        ,maxValue:5
                        ,minText:'Saisir une valeur entre 1 et 5'
                        ,maxText:'Saisir une valeur entre 1 et 5'
                        ,listeners: {render: function(c){Ext.QuickTips.register({target: c.getEl(),text:'Relief amont-aval (voir la fiche). Une valeur comprise entre 1 et 5.' });}}
                    },{
                        xtype: 'displayfield'
                        ,value: 'gauche-droite'
                    },{
                        id: 'fieldstation-meso_lateral'
                        ,name: 'meso_lateral'
                        ,width: 50
                        ,maxValue:3
                        ,minText:'Saisir une valeur entre 1 et 3'
                        ,maxText:'Saisir une valeur entre 1 et 3'
                        ,listeners: {render: function(c){Ext.QuickTips.register({target: c.getEl(),text:'Relief gauche-droite (voir la fiche). Une valeur comprise entre 1 et 3.' });}}
                    }]
                }]
            }// fin du sous groupe relief
            ,{
                id: 'fieldstation-canopee'
                ,allowDecimals :false
                ,allowNegative: false
                ,fieldLabel: 'Hauteur de l\'arbre le plus haut '
                ,name: 'canopee'
                ,anchor: '40%'                
            }
            ,{ //ssgroupe stratification
            xtype:'fieldset'
            ,id:'fieldset-strates'
            ,columnWidth: 1
            ,title: 'Strates de végétation'
            ,collapsible: false
            ,autoHeight:true
            ,anchor:'98%'
            ,defaults: {
                anchor: '40%'
                ,allowDecimals :false
                ,allowNegative: false
                ,minValue:0
                ,maxValue:100
                ,nanText:'Seul un nombre entier positif entre 0 et 100 est possible.'
                ,listeners: {render: function(c){Ext.QuickTips.register({target: c.getEl(),text: 'Saisir en pourcentage (nombre entier positif entre 0 et 100), la surface de recouvrement de chaque strate de végétation. La somme des pourcentages de recouvrement des strates peut dépasser 100%.'});}}
            }
            ,defaultType: 'numberfield'
            ,items :[{
                    id: 'fieldstation-ligneux_hauts'
                    ,fieldLabel: 'Ligneux hauts '
                    ,name: 'ligneux_hauts'
                    ,labelSeparator:''
                },{
                    id: 'fieldstation-ligneux_bas'
                    ,fieldLabel: 'Ligneux bas '
                    ,name: 'ligneux_bas'
                    ,labelSeparator:''
                },{
                    id: 'fieldstation-ligneux_tbas'
                    ,fieldLabel: 'Ligneux très bas '
                    ,name: 'ligneux_tbas'
                    ,labelSeparator:''
                },{
                    id: 'fieldstation-herbaces'
                    ,fieldLabel: 'Herbacés '
                    ,name: 'herbaces'
                    ,labelSeparator:''
                },{
                    id: 'fieldstation-mousses'
                    ,fieldLabel: 'Mousses '
                    ,name: 'mousses'
                    ,labelSeparator:''
                },{
                    id: 'fieldstation-litiere'
                    ,fieldLabel: 'Litière '
                    ,name: 'litiere'
                    ,labelSeparator:''
                }]
            },{
                xtype: 'compositefield'
                ,fieldLabel: 'Code delphine '
                ,msgTarget : 'side'
                // ,anchor    : '-20',
                ,defaults: {
                    flex: 1
                },
                items: [{
                    id:'textfield-station-delphine1'
                    ,xtype: 'textfield'
                    ,name: 'id_delphine1'
                    ,maxLength:5
                    ,maxLengthText:'Un code delphine ne doit pas comporter plus de 5 caractères.'
                    ,anchor:'90%'
                    // ,width:250
                    ,listeners: {
                        render: function(c) {
                            Ext.QuickTips.register({
                                target: c.getEl(),
                                text: 'Voir "Groupements végétaux du Parc national des Ecrins" - 5 caractères maximum.'
                            });
                        }
                    }
                },{
                    id:'textfield-station-delphine2'
                    ,xtype: 'textfield'
                    ,name: 'id_delphine2'
                    ,maxLength:5
                    ,maxLengthText:'Un code delphine ne doit pas comporter plus de 5 caractères.'
                    ,anchor:'90%'
                    ,listeners: {
                        render: function(c) {
                            Ext.QuickTips.register({
                                target: c.getEl(),
                                text: 'Voir "Groupements végétaux du Parc national des Ecrins" - 5 caractères maximum.'
                            });
                        }
                    }
                }]
            },{
                id:'ta-station-remarques'
                ,xtype: 'textarea'
                ,fieldLabel: 'Remarques '
                ,name: 'remarques'
                ,grow:true
                ,autoHeight: true
                ,height:'auto'
                ,anchor:'95%'
                ,listeners: {
                    render: function(c) {
                        Ext.QuickTips.register({
                            target: c.getEl(),
                            text: 'Mettre en remarque tout ce qui semble utile et qui n\'est pas prévu dans la fiche.'
                        });
                    }
                }
            }]
        }//fin du groupe 3
        ] //fin du return
    };
    var myProxy = new Ext.data.HttpProxy({
        id:'store-taxon-proxy'
        ,url: 'station/getonerelevetaxons?id_station='+id_station
        ,method: 'GET'
    });
    var gridStoreTaxonsLoad = function(id_station) {
        myProxy.api.read.url = 'station/getonerelevetaxons?id_station='+id_station;
        gridStoreTaxons.reload();
    };
    var getFormTaxons = function(){
        var taxon = Ext.data.Record.create([
            {name: 'id_station',type: 'integer'}   
            ,{name: 'cd_nom',type: 'integer'}
            ,{name: 'nom_complet',type: 'string'}
            ,{name: 'herb',type: 'integer'}
            ,{name: 'inf_1m',type: 'integer'}
            ,{name: 'de_1_4m',type: 'integer'}
            ,{name: 'sup_4m',type: 'integer'}
        ]);
        var editor = new Ext.ux.grid.RowEditor({
            saveText: 'Enregistrer'
        });
        
        gridStoreTaxons = new Ext.data.JsonStore({
            // url: 'station/getonerelevetaxons'
            proxy: myProxy
            ,fields: [
                {name:'id_station'}
                ,{name:'cd_nom'}
                ,{name:'nom_complet'}
                ,{name:'herb'}
                ,{name:'inf_1m'}
                ,{name:'de_1_4m'}
                ,{name:'sup_4m'}
                ,{name:'taxon_saisi'}
            ]
            ,sortInfo: {
                field: 'nom_complet'
                ,direction: 'ASC'
            }
            // ,autoLoad:true
            // ,listeners:{
                // load: function(grid,rowIndex){
                    
                // }
            // }
        });

        var taxonsEditGrid = new Ext.grid.GridPanel({
            id:'grid-edit-taxon'
            ,store: gridStoreTaxons
            ,width: 580
            ,region:'center'
            ,margins: '0 5 5 5'
            ,autoExpandColumn: 'col-cd_nom'
            ,plugins: [editor]
            ,view: new Ext.grid.GridView({
                markDirty: false
            })
            ,tbar: [{
                iconCls: 'add'
                ,text: 'Nouveau taxon'
                ,handler: function(){
                    newTaxon();
                }
            },{
                ref: '../removeBtn'
                ,iconCls: 'action-remove'
                ,text: 'Supprimer ce taxon'
                ,disabled: true
                ,handler: function(){
                    editor.stopEditing();
                    var s = taxonsEditGrid.getSelectionModel().getSelections();
                    for(var i = 0,r; r = s[i]; i++){
                        var moncdnom = r.data.cd_nom;    
                        var maligne = r;//décidemment je n'y comprend rien en porté de variable en javascript    
                        Ext.Msg.confirm('Attention'
                                ,'Etes-vous certain de vouloir supprimer le taxon '+r.data.taxon_saisi +' ?'
                                ,function(btn) {
                                    if (btn == 'yes') {
                                        Ext.Ajax.request({
                                            url: 'station/deletetaxon'
                                            ,method: 'POST'
                                            ,params: {
                                                cd_nom: moncdnom
                                                ,id_station: Ext.getCmp('edit-station-form').getForm().findField('id_station').getValue()
                                            }
                                            ,success: function(request) {
                                                var result = Ext.decode(request.responseText);
                                                if (result.success) {
                                                    Ext.ux.Toast.msg('Ok !', 'Le taxon à été supprimé.');
                                                    var index = 'station-' + Ext.getCmp('edit-station-form').getForm().findField('id_station').getValue();
                                                    var tab = application.layout.tabPanel.getComponent(index);
                                                    if(tab){
                                                        tab.refreshTaxons();
                                                        tab.refreshStation();
                                                    }
                                                    gridStoreTaxons.remove(maligne);
                                                } else {
                                                    OpenLayers.Console.error("une erreur s'est produite !");
                                                }
                                            }
                                            ,failure: application.checklog
                                            // ,scope: this
                                        });
                                    }
                                }
                            );
                            
                    }
                }
            },{
                iconCls: 'back_to_search'
                ,text: 'Référence'
                ,handler: function(){
                    application.editStation.initTaxrefWindow();
                }
            }]
            ,columns: [
            // new Ext.grid.RowNumberer()
            {
                header: 'Taxon saisi'
                ,dataIndex: 'taxon_saisi'
                ,width: 50
                ,sortable: true
                ,hidden:true
                ,editor: {
                    id:'editor-taxonsaisi'
                    ,xtype: 'textfield'
                }
            },{
                id: 'col-cd_nom'
                ,header: 'Taxon'
                ,dataIndex: 'cd_nom'
                ,width: 150
                ,sortable: true
                ,editor: {
                    id:'combo-taxons'
                    ,name: 'cd_nom'
                    ,xtype:"twintriggercombo"
                    ,hiddenName:"cd_nom"
                    ,store: application.filtreTaxonsReferenceStore
                    ,valueField: "cd_nom"
                    ,displayField: "nom_complet"
                    ,storeField: ['cd_nom', 'nom_complet']
                    // ,allowBlank: false
                    // ,blankText:'Vous devez fournir un taxon <br>et sa fréquence dans au moins une strate'
                    ,typeAhead: true
                    ,typeAheadDelay:750
                    ,forceSelection: true
                    ,selectOnFocus: true
                    ,editable: true
                    ,resizable : true
                    ,triggerAction: 'all'
                    ,trigger3Class: 'x-form-zoomto-trigger x-hidden'
                    ,mode: 'local'
                    ,listeners: {
                        select: function(combo,record,index) {
                            var s = Ext.getCmp('grid-edit-taxon').getSelectionModel().getSelections();
                            rec = s[0];
                            //on vérifie que le taxon choisi n'est pas déjà dans la liste
                            var compt = 0;
                            var val = combo.getValue();
                            gridStoreTaxons.each(function(r){
                                if(r.data.cd_nom==val){compt ++;}
                            });
                            if (compt>=1){
                                Ext.Msg.show({
                                    title: 'Attention'
                                    ,buttons: Ext.Msg.OK,icon: Ext.MessageBox.ERROR
                                    ,msg:'Attention ! Ce taxon existe déjà dans la liste.'
                                    ,fn: function(){
                                        // combo.setValue(combo.originalValue);
                                        Ext.getCmp('grid-edit-taxon').plugins[0].stopEditing(false);
                                    }
                                });
                            }
                            else{
                                rec.data.taxon_saisi = combo.getRawValue();
                                Ext.getCmp('editor-taxonsaisi').setValue(combo.getRawValue());
                                rec.commit();
                            }                    
                        }
                        ,beforeedit:function(grid,record,field,value,row,column) {
                            // application.utils.getRecordDisplayFieldValue(grid, 1, value, 'cd_nom', 'nom_complet');
                        }
                        ,afterrender: function(combo){
                            combo.keyNav.tab = function() { // Override TAB handling function
                                this.onViewClick(false); // Select the currently highlighted row
                            };
                        }
                    }
                }
                ,renderer:function(value, metaData, record, rowIndex, colIndex) { return application.utils.getRecordDisplayFieldValue(taxonsEditGrid, colIndex, value, 'cd_nom', 'nom_complet'); }
            },{
                header: 'Herb.'
                ,dataIndex: 'herb'
                ,width: 50
                ,sortable: true
                ,editor: {
                    xtype: 'textfield'
                }
            },{
                header: 'Inf 1m'
                ,dataIndex: 'inf_1m'
                ,width: 50
                ,sortable: true
                ,editor: {
                    xtype: 'textfield'
                }
            },{
                header: '1 à 4m'
                ,dataIndex: 'de_1_4m'
                ,width: 50
                ,sortable: true
                ,editor: {
                    xtype: 'textfield'
                }
            },{
                header: 'Sup 4m'
                ,dataIndex: 'sup_4m'
                ,width: 50
                ,sortable: true
                ,editor: {
                    xtype: 'textfield'
                }
            }]
        });

        // store.on('add', cstore.refreshData, cstore);
        // store.on('remove', cstore.refreshData, cstore);
        // store.on('update', cstore.refreshData, cstore);

        var taxonsPanel = new Ext.Panel({
            id:'taxons-liste-panel'
            ,title: 'Liste des taxons'
            ,layout: 'border'
            ,layoutConfig: {
                columns: 1
            }
            ,width: 580
            ,height: 500
            ,items: [taxonsEditGrid]
        });
        
         /**
         * Method: newTaxon
         * add a taxon record into the editorGrid
         */
        var newTaxon = function(){
            var t = new taxon({
                id_station: id_station
            });
            editor.stopEditing();
            gridStoreTaxons.insert(0, t);
            // taxonsEditGrid.getView().refresh();
            taxonsEditGrid.getSelectionModel().selectRow(0);
            editor.startEditing(0);
            Ext.getCmp('edit-station-form').getForm().findField('monaction').setValue('update');
        }
        
        /**
         * Method: submitTaxon
         * Submits the taxon record to CorFsTaxon
         */
        var submitTaxon = function(id_station,new_cd_nom,old_cd_nom, herb, inf_1m, de_1_4m, sup_4m,taxon_saisi) {
            Ext.getCmp('taxons-liste-panel').setTitle('Liste des taxons (Enregistrement en cours...)');
            if (id_station) {
                var params = {};
                params.id_station = id_station;
                params.new_cd_nom = new_cd_nom;
                params.old_cd_nom = old_cd_nom;
                params.herb = herb;
                params.inf_1m = inf_1m;
                params.de_1_4m = de_1_4m;
                params.sup_4m = sup_4m;
                params.taxon_saisi = taxon_saisi;
            
                Ext.Ajax.request({
                    url: 'station/savetaxon'
                    ,params: params
                    ,success: function(result, request) {
                        Ext.getCmp('taxons-liste-panel').setTitle('Liste des taxons');
                        Ext.ux.Toast.msg('Ok !', 'La liste des taxons a été mise à jour.');
                        var index = 'station-' + Ext.getCmp('edit-station-form').getForm().findField('id_station').getValue();
                        var tab = application.layout.tabPanel.getComponent(index);
                        if(tab){
                            tab.refreshTaxons();
                            tab.refreshStation();
                        }
                    }
                    ,failure: function(result, request) {
                        Ext.getCmp('taxons-liste-panel').setTitle('Liste des taxons');
                        Ext.Msg.show({
                          title: 'Erreur'
                          ,msg: 'L\'enregistrement n\'a pas été réalisé'
                          ,buttons: Ext.Msg.OK
                          ,icon: Ext.MessageBox.ERROR
                        });
                    }
                    
                });
            }
            else{
            Ext.Msg.show({
                  title: 'Attention'
                  ,msg: 'Vous devez d\'abord enregistrer la station et obtenir un N° de station - L\'enregistrement n\'a pas été réalisé'
                  ,buttons: Ext.Msg.OK
                  ,icon: Ext.MessageBox.ERROR
                });
            }
        };
        
        taxonsEditGrid.getSelectionModel().on('selectionchange', function(sm){
            taxonsEditGrid.removeBtn.setDisabled(sm.getCount() < 1);
        });
        //definir le cd_nom d'origine pour retrouver dans la base la double clé id_station/cd_nom
        editor.on('beforeedit', function(grid, rowIndex){
            var s = taxonsEditGrid.getSelectionModel().getSelections();
                r = s[0].data;
                old_cd_nom = r.cd_nom;
        });
        editor.on('canceledit', function(grid){
            var s = taxonsEditGrid.getSelectionModel().getSelections();
            var r = s[0];
            if(!r.data.cd_nom > 0){gridStoreTaxons.remove(r);}
        });

        //action sur le bouton "Enregistrer" ligne par ligne
        editor.on('afteredit', function(grid, object, record, rowIndex){
            var r = record.data;
            monidstation = Ext.getCmp('edit-station-form').getForm().findField('id_station').getValue();
            // On vérifie qu'un taxon est saisi
            if(!r.cd_nom>0){
                Ext.Msg.show({
                    title: 'Attention'
                    ,buttons: Ext.Msg.OK,icon: Ext.MessageBox.ERROR
                    ,msg:'Attention ! Vous n\'avez pas choisi de taxon.'
                    ,fn: function(){
                        var s = taxonsEditGrid.getSelectionModel().getSelections();
                        var r = s[0];
                        gridStoreTaxons.remove(r);
                        newTaxon();
                    }
                });
            }
            else{
            
                // else{
                //validation pour savoir si on a au moins une valeur dans une des 4 strates
                var machaine = r.herb+r.inf_1m+r.de_1_4m+r.sup_4m;
                if(machaine.length>0){submitTaxon(monidstation,r.cd_nom, old_cd_nom, r.herb, r.inf_1m, r.de_1_4m, r.sup_4m,r.taxon_saisi);}
                else{
                    Ext.Msg.show({
                        title: 'Attention'
                        ,buttons: Ext.Msg.OK,icon: Ext.MessageBox.ERROR
                        ,msg:'Attention ! Fournissez une valeur pour au moins une strate.'
                        ,fn: function(){
                            Ext.getCmp('grid-edit-taxon').getSelectionModel().selectRow(rowIndex);
                            Ext.getCmp('grid-edit-taxon').plugins[0].startEditing(rowIndex,1);
                        }
                    });
                }
                // }
            }
        });
        //ajout d'un taxon avec la touche 'n' ou la barre d'espace
        Ext.getCmp('grid-edit-taxon').on('keydown', function (el) {
            if(el.keyCode == 78 || el.keyCode == 32) {
                el.preventDefault();
                newTaxon();
            }
        });
        return taxonsPanel;
    };
    
    /**
     * Method: createLayer
     * Creates the vector layer
     *
     * Return
     * <OpenLayers.Layer.Vector>
     */
    var createLayer = function() {
        var styleMap = new OpenLayers.StyleMap({
            'default': {
                fillColor: "red"
                ,strokeColor: "#ff6666"
                ,cursor: "pointer"
                ,fillOpacity: 0.7
                ,strokeOpacity: 1
                ,strokeWidth: 2
                ,pointRadius: 7
            }
            ,select : {
                fillColor: "blue"
                ,strokeColor: "blue"
                ,cursor: "pointer"
                ,fillOpacity: 0.5
                ,strokeOpacity: 1
                ,strokeWidth: 3
                ,pointRadius: 8
            }
        });
        vectorLayer = new OpenLayers.Layer.Vector("editStation vector layer"
            ,{
                protocol: eventProtocol
                ,strategies: [
                    new mapfish.Strategy.ProtocolListener()
                ]
                ,styleMap: styleMap
                ,format: OpenLayers.Format.GeoJSON
            }
        );
        vectorLayer.events.on({
            featureadded: function(obj) {
                var feature = obj.feature;
                // don't allow BD or massif geometry editing
                if (this.id_station==null) {
                    activateControls(false);
                } else {
                    deactivateAllEditingControls();
                }
                updateGeometryField(feature);
                if(!firstAltitudeLoad){application.editStation.findZ(feature);}
                firstAltitudeLoad = false;
                Ext.getCmp('edit-station-form').enable();
                Ext.getCmp('edit-station-form').ownerCt.ownerCt.doLayout();
            }
            ,featuremodified: function(obj) {
                updateGeometryField(obj.feature);
            }
            ,featureremoved: function(obj) {
                updateGeometryField(null);
                Ext.getCmp('edit-station-form').disable();
            }
        });
    };

    /**
     * Method: createMap
     * Creates the map
     *
     * Return
     * <OpenLayers.Map>
     */
    var createMap = function() {
        map = application.createMap();
        map.getLayersByName('overlay')[0].mergeNewParams({
          id_station:id_station
        });
        createLayer();
        map.addLayers([vectorLayer]);
        map.zoomToMaxExtent();
        maProjection = map.getProjectionObject();
    };

    /**
     * Method: initToolbarItems
     * Creates the map toolbar
     */
    var initToolbarItems = function() {
        if (!toolbarInitializedOnce) {
            toolbar.addControl(
                new OpenLayers.Control.ZoomToMaxExtent({
                    map: map,
                    title: 'Revenir à l\'échelle maximale'
                }), {
                    iconCls: 'zoomfull',
                    toggleGroup: this.id
                }
            );

            application.utils.addSeparator(toolbar);

            toolbar.addControl(
                new OpenLayers.Control.ZoomBox({
                    title: 'Zoomer'
                }), {
                    iconCls: 'zoomin',
                    toggleGroup: this.id
                }
            );

            toolbar.addControl(
                new OpenLayers.Control.ZoomBox({
                    out: true,
                    title: 'Dézoomer'
                }), {
                    iconCls: 'zoomout',
                    toggleGroup: this.id
                }
            );

            toolbar.addControl(
                dragPanControl = new OpenLayers.Control.DragPan({
                    isDefault: true,
                    title: 'Déplacer la carte'
                }), {
                    iconCls: 'pan',
                    toggleGroup: this.id
                }
            );

            application.utils.addSeparator(toolbar);

            toolbar.addControl(
                drawPointControl = new OpenLayers.Control.DrawFeature(vectorLayer, OpenLayers.Handler.Point, {
                    title: 'Localiser la station'
                }), {
                    iconCls: 'drawpoint'
                    ,toggleGroup: this.id
                    ,disabled: true
                }
            );
            
            toolbar.add({
                text: 'GPS'
                ,id: 'edit-station-gps'
                ,tooltip: 'Localiser la station sur la carte à partir de coordonnées GPS'
                ,handler: function() {
                    vectorLayer.removeFeatures(vectorLayer.features[0]);
                    application.editStation.initGpsWindow();
                }
            });
            
            toolbar.addControl(
                dragPolygonControl = new OpenLayers.Control.DragFeature(vectorLayer, {
                    title: 'Déplacer la station'
                    ,onComplete:function(feature) {
                        updateGeometryField(feature);
                    }
                }), {
                    iconCls: 'dragpolygon'
                    ,toggleGroup: this.id
                    ,disabled: true
                }
            );

            application.utils.addSeparator(toolbar);

            toolbar.add({
                text: 'Effacer la géométrie'
                ,id: 'edit-station-geometry-erase'
                //,disabled: true
                ,iconCls: 'erase'
                ,tooltip: 'Permet de supprimer la géométrie pour en créer une nouvelle'
                ,handler: function() {
                    Ext.Msg.confirm('Attention'
                        ,'Cela supprimera définitivement la géométrie existante !<br />Confirmer ?'
                        ,function(btn) {
                            if (btn == 'yes') {
                                activateControls(true);
                                vectorLayer.removeFeatures(vectorLayer.features[0]);
                            }
                        }
                    )
                }
            });

            layerTreeTip = application.createLayerWindow(map);
            layerTreeTip.render(Ext.getCmp('edit-station-mapcomponent').body);
            layerTreeTip.show();
            layerTreeTip.getEl().alignTo(
                Ext.getCmp('edit-station-mapcomponent').body,
                "tl-tl",
                [5, 5]
            );
            layerTreeTip.hide();

            application.utils.addSeparator(toolbar);

            toolbar.add({
                iconCls: 'legend'
                ,enableToggle: true
                ,tooltip: 'Gérer les couches affichées'
                ,handler: function(button) {
                    showLayerTreeTip(button.pressed);
                }
            });

            toolbar.activate();
            toolbarInitializedOnce = true;

            // Ext.getCmp('edit-station-status').add({
                // text: 'Annuler'
                // ,xtype: 'button'
                // ,handler: function() {
                    // application.editStation.window.hide();
                // }
                // ,scope: this
            // },{
                // text: 'Enregistrer'
                // ,xtype: 'button'
                // ,id: 'stationSaveButton'
                // ,iconCls: 'action-save'
                // ,handler:submitForm
            // });
        }
    };

    /**
     * Method: activateControls
     * Allows to activate / enable / deactivate / disable the draw and modify feature controls
     *
     * Parameters:
     * activateDrawControls - {Boolean} true to activate / enable the draw controls
     */
    var activateControls = function(activateDrawControls) {
        Ext.getCmp('edit-station-geometry-erase').setDisabled(false);
        toolbar.getButtonForControl(dragPolygonControl).setDisabled(activateDrawControls);
        if (activateDrawControls) {
            dragPolygonControl.deactivate();
        } else {
            dragPolygonControl.activate();
        }
        Ext.each([drawPointControl]
            ,function(control) {
                toolbar.getButtonForControl(control).setDisabled(!activateDrawControls);
                if (!activateDrawControls) {
                    control.deactivate();
                }
            }
        );
    };

    /**
     * Method: deactivateAllEditingControls
     */
    var deactivateAllEditingControls = function() {
        Ext.getCmp('edit-station-geometry-erase').setDisabled(true);
        toolbar.getButtonForControl(dragPolygonControl).setDisabled(true);
        dragPolygonControl.deactivate();
        toolbar.getButtonForControl(drawPointControl).setDisabled(true);
        drawPointControl.deactivate();
    };

    /**
     * Method: updateGeometryField
     * Updates the geometry field (hidden) in the form
     *
     * Parameters:
     * geometry - {null|<OpenLayers.Geometry>} Geometry
     */
    var updateGeometryField = function(geometry) {
        if (geometry == null) {wkt = '';}
        else {var wkt = format.write(geometry);}
        Ext.getCmp('edit-station-form').getForm().findField('geometry').setValue(wkt);
        firstGeometryLoad = false;
    };
    
    /**
     * Method: createProtocol
     * Create the search protocol.
     */
    var createProtocol = function() {
        protocol = new mapfish.Protocol.MapFish({});
        eventProtocol = new mapfish.Protocol.TriggerEventDecorator({
            protocol: protocol
            ,eventListeners: {
                crudtriggered: function() {
                    //apsListGrid.loadMask.show();
                }
                ,crudfinished: function(response) {
                    var feature = response.features[0];
                    //mise à jour des label du formulaire
                    Ext.getCmp('labelstation-station').setText('<p class="bluetext">Station N° '+feature.data.id_station+' du '+feature.data.dateobs+' ('+feature.data.commune+')</p>',false);
                    //chargement des valeurs du formulaire
                    Ext.getCmp('edit-station-form').getForm().loadRecord(feature);
                    //on centre en positionnant le zoom à 15
                    var centerGeom = feature.geometry.getBounds().getCenterLonLat();
                    map.setCenter(centerGeom,15);
                    Ext.getCmp('edit-station-form').enable();
                    if(Ext.getCmp('combo-station-programme').getValue()==101){
                        Ext.getCmp('textfield-station-sophie').showItem();
                        Ext.getCmp('textfield-station-sophie').show();
                    }
                    else{
                        Ext.getCmp('textfield-station-sophie').setValue(0);
                        Ext.getCmp('textfield-station-sophie').hideItem();
                        Ext.getCmp('textfield-station-sophie').hide();                        
                    }
                }
            }
        });
    };

    /**
     * Method: createStore
     * Create the search result store.
     */
    var createStore = function() {
        store = new Ext.data.Store({
            reader: new mapfish.widgets.data.FeatureReader({}, [
                'id_station'
                ,'ids_observateurs'
                ,{name:'dateobs', type: 'date', dateFormat:'d/m/Y'}
                ,'complet_partiel'
                ,'altitude'
                ,'id_sophie'
                ,'id_support'
                ,'pdop'
                ,'id_programme_fs'
                ,'id_exposition'
                ,'id_homogene'
                ,'id_microrelief1'
                ,'id_microrelief2'
                ,'id_microrelief3'
                ,'id_surface'
                ,'info_acces'
                ,'commune'
                ,'meso_longitudinal'
                ,'meso_lateral'
                ,'canopee'
                ,'ligneux_hauts'
                ,'ligneux_bas'
                ,'ligneux_tbas'
                ,'herbaces'
                ,'mousses'
                ,'litiere'
                ,'remarques'
                ,'id_delphine1'
                ,'id_delphine2'
            ])
            ,listeners: {
                load: function(store, records) {
                    Ext.getCmp('edit-station-form').getForm().loadRecord(records[0]);
                }
            }
        });
    };

    /**
     * Method: resetWindow
     * Reset the different items status (on close) for next usage
     */
    var resetWindow = function() {
        Ext.getCmp('grid-edit-taxon').plugins[0].stopEditing(true);
        id_station = null;
        map.zoomToMaxExtent();
        vectorLayer.removeFeatures(vectorLayer.features);
        Ext.getCmp('edit-station-form').disable();
        Ext.getCmp('edit-station-form').getForm().reset();
        dragPanControl.activate();
        if(Ext.getCmp('station_count').setText("les 50 dernières stations")){
            Ext.getCmp('hidden-start').setValue('yes')
            application.search.refreshStations();
        }
    };

    /**
     * Method: submitForm
     * Submits the form
     */
    var submitForm = function() {
        Ext.getCmp('stationSaveButton').setText('Enregistrement en cours...');
        var params = {};
        if (id_station) {
            params.id_station = id_station;
        }
        Ext.getCmp('edit-station-form').getForm().submit({
            url: 'station/save'
            ,params: params
            ,success: function(form,action) {
                Ext.getCmp('stationSaveButton').setText('Enregistrer');
                if (id_station) {
                    var index = 'station-' + Ext.getCmp('edit-station-form').getForm().findField('id_station').getValue();
                    var tab = application.layout.tabPanel.getComponent(index);
                    if(tab){
                        tab.refreshTaxons();
                        tab.refreshStation();
                    }
                    application.editStation.window.hide();
                }
                else{
                    var madateobs = new Date();
                    madateobs = Ext.getCmp('edit-station-form').getForm().findField('dateobs').getValue();
                    madateobs.format("d/m/Y");
                    Ext.getCmp('edit-station-form').getForm().findField('id_station').setValue(action.result.id_station);
                    Ext.getCmp('labelstation-station').setText('<p class="bluetext">Station N° '+action.result.id_station+' du '+madateobs+' ('+action.result.commune+')</p>',false);
                    Ext.getCmp('edit-station-form').getForm().findField('monaction').setValue('update');
                    Ext.getCmp('taxons-liste-panel').show();
                } 
            }
            ,failure: function(form, action) {
                Ext.getCmp('stationSaveButton').setText('Enregistrer');
                var msg;
                switch (action.failureType) {
                      case Ext.form.Action.CLIENT_INVALID:
                          msg = "Les informations saisies sont invalides ou incomplètes. Vérifiez le formulaire (voir champs en rouge).";
                          break;
                      case Ext.form.Action.CONNECT_FAILURE:
                          msg = "Problème de connexion au serveur";
                          break;
                      case Ext.form.Action.SERVER_INVALID:
                          msg = "Erreur lors de l'enregistrement : vérifier les données saisies !";
                          break;
                }
                Ext.Msg.show({
                  title: 'Erreur'
                  ,msg: msg
                  ,buttons: Ext.Msg.OK
                  ,icon: Ext.MessageBox.ERROR
                });
            }
        });
    };

    /**
     * Method: showLayerTreeTip
     * Shows or hide the layer tree tip
     */
    var showLayerTreeTip = function(show) {
        layerTreeTip.setVisible(show);
    };
 
//----------------------------------fenêtre de recherche des synonymes taxonomiques----------------------------------
    var submitFormTaxref = function() {
        if(Ext.getCmp('form-taxref-station').getForm().isValid()){
            Ext.getCmp('form-taxref-station').setTitle('Rechercher le taxon de référence (recherche en cours...)');
                var params = {};
                params.lb_nom = Ext.getCmp('form-taxref-station').getForm().findField('taxon_name').getValue();
                params.cd_nom = Ext.getCmp('form-taxref-station').getForm().findField('taxon_code').getValue();
                Ext.Ajax.request({
                    url: 'taxon/getref'
                    ,params: params
                    ,success: function(request) {
                        var result = Ext.decode(request.responseText);
                        Ext.getCmp('form-taxref-station').setTitle('Rechercher le taxon de référence');
                        Ext.getCmp('panel-result-taxref').update(result.text);
                        Ext.ux.Toast.msg('Et voilà !', 'Regarde si le résultat te convient !.');
                    }
                    ,failure: function(form, action) {
                        Ext.getCmp('form-taxref-station').setTitle('Rechercher le taxon de référence');
                        Ext.Msg.show({
                          title: 'houps !'
                          ,msg: 'Il doit y avoir une erreur quelque part...'
                          ,buttons: Ext.Msg.OK
                          ,icon: Ext.MessageBox.ERROR
                        });
                    }
                    
                });
        }
        else{
            Ext.Msg.alert('Attention', 'Une information est mal saisie ou n\'est pas valide.</br>Vous devez la corriger avant de poursuivre.');
        }
    };
    
    var initTaxrefWindow = function() {
        return new Ext.Window({
            id:'window-taxref'
            ,layout:'border'
            ,height:425
            ,width: 600
            ,closeAction:'hide'
            ,autoScroll:true
            ,modal: true
            ,plain: true
            ,split: true
            ,buttons: [{
                text:'Trouver'
                ,id:'taxref-afficher-button'
                ,handler: function(){
                    submitFormTaxref();
                }
            },{
                text: 'Fermer'
                ,handler: function(){
                    Ext.getCmp('window-taxref').destroy();
                }
            }]
            ,items: [{
                id:'form-taxref-station'
                ,xtype: 'form'
                ,title: 'Rechercher le taxon de référence'
                ,region: 'center'
                ,labelWidth: 200 // label settings here cascade unless overridden
                ,frame:true
                ,border:false
                ,split: false
                ,autoScroll:true
                ,monitorValid:true
                ,bodyStyle:'padding:5px 5px 0'
                ,width: 550
                ,defaultType: 'textfield'
                ,items: [{
                    id: 'taxref-station-name'
                    ,fieldLabel: 'nom du taxon (latin ou français)'
                    ,allowBlank:true
                    ,minLength : 3
                    ,minLengthText: 'Afin d\'éviter des recherches trop générale, saisir au moins 3 caractères avant de lancer la recherche.'
                    ,blankText: 'Vous devez entrer le nom du taxon recherché ici ; au moins trois caractères.'
                    ,name: 'taxon_name'
                    ,anchor: '95%'
                    ,enableKeyEvents :true
                    ,listeners: {
                        keyup:function(){Ext.getCmp('taxref-station-code').setValue(null);}
                    }
                    
                },{
                    id: 'taxref-station-code'
                    ,xtype:'numberfield'
                    ,fieldLabel: 'cd_nom ou cd_ref'
                    ,allowDecimals :false
                    ,allowNegative: false
                    ,allowBlank:true
                    ,name: 'taxon_code'
                    ,anchor: '60%'
                    ,enableKeyEvents: true
                    ,listeners: {
                        keyup:function(){Ext.getCmp('taxref-station-name').setValue(null);}
                    }
                }]
                ,keys: [
                    { 
                        key: [Ext.EventObject.ENTER]
                        ,handler: function() {
                            submitFormTaxref();
                        }
                    }
                ]
            },{
                id:'panel-result-taxref'
                ,xtype: 'panel'
                ,region: 'south'
                ,frame:true
                ,border:false
                ,split: false
                ,autoScroll:true
                ,bodyStyle:'padding:5px 5px 0'
                ,width: 550
                ,height : 250
                ,html: '<div style="text-align:center;width:550px;height:225px">Saisissez ci-dessus le nom scientifique ou le nom vernaculaire du taxon recherché (ou une partie de son nom). Le taxon de référence correpondant ainsi que la liste de ses éventuels synonymes s\'afficheront ici.< /div>'
            }]
            ,listeners: {
                hide:function(){this.destroy();}
            } 
        });
    };
//----------------------------------fin de fenêtre de recherche des synonymes taxonomiques----------------------------------

    // public space
    return {

        window: null

        ,init: function() {
            createProtocol();
            createStore();
            this.window = initWindow();
        }
        
        /**
         * Method: loadAp
         * Loads a record from the aps list store
         */
        ,loadStation: function(id,action,cd) {
            if (!this.window) {
                this.init();
            }
            this.window.show();
            if (action=='update') {
                firstAltitudeLoad = true;
                Ext.getCmp('edit-station-form').getForm().findField('monaction').setValue('update');
                this.window.setTitle('Modification d\'une station');
                if (id) {
                    id_station = id;
                    wmslayer = map.getLayersByName('overlay')[0];
                    wmslayer.mergeNewParams({
                      id_station: id_station
                    });
                    wmslayer.setOpacity(0.25);
                    var options = {
                        url: ['station/get', id_station].join('/')
                        ,params: {format: 'geoJSON'}
                    };
                    eventProtocol.read(options);
                    //si l'évenement load a un listener on le supprime
                    if(gridStoreTaxons.hasListener('load')){gridStoreTaxons.events['load'].clearListeners();}
                    //si on passe un cd_nom à modifier, on ajout un listener sur load pour mettre ce taxon en édition
                    if(cd>0){
                        gridStoreTaxons.addListener('load',function(){
                            var monIndex = gridStoreTaxons.findExact('cd_nom',cd);
                            old_taxon = cd;
                            // alert("cd : "+cd+" index : "+monIndex);
                            Ext.getCmp('grid-edit-taxon').getSelectionModel().selectRow(monIndex);
                            Ext.getCmp('grid-edit-taxon').plugins[0].startEditing(monIndex,1);
                        });
                    }
                    gridStoreTaxonsLoad(id_station);
                    Ext.getCmp('taxons-liste-panel').show();
                }
            }
            if (action=='add') {
                firstAltitudeLoad = false;
                activateControls(true);
                updateGeometryField(null);
                Ext.getCmp('edit-station-form').getForm().findField('monaction').setValue('add');
                Ext.getCmp('labelstation-station').setText( '<p class="redtext">Nouvelle station - saisir puis enregistrer pour obtenir un N° de station</p>',false);
                this.window.setTitle('Ajout d\'une nouvelle station');
                Ext.getCmp('taxons-liste-panel').hide();
                Ext.ux.Toast.msg('Attention !', 'Commencer par saisir la position de la station sur la carte pour activer le formulaire');
                Ext.getCmp('textfield-station-sophie').setValue(0);
                Ext.getCmp('textfield-station-sophie').hideItem();
                Ext.getCmp('textfield-station-sophie').hide();
                gridStoreTaxons.removeAll();
            }
            map.zoomToMaxExtent();
        }

        ,initGpsWindow: function() {
            this.GpsWindow = Ext.ux.GpsLocation.initGpsWindow(vectorLayer);
            this.GpsWindow.show();
        }
        ,initTaxrefWindow: function() {
            this.TaxrefWindow = initTaxrefWindow();
            this.TaxrefWindow.show();
        }
        
        //remplir l'altitude du champ altitude dans le formulaire selon le pointage
        ,findZ : function(feature) {
            //on recherche l'altitude avec l'API IGN
            var geometryCentroid = feature.geometry.getCentroid();
            var latLonGeom = geometryCentroid.transform(new OpenLayers.Projection("EPSG:3857"), new OpenLayers.Projection("EPSG:4326"));
            var script = document.createElement('script');
            script.src = String.format('//wxs.ign.fr/{0}/alti/rest/elevation.xml?lon={1}&lat={2}&output=json&zonly=true&callback=application.editStation.handleIGNResponse', ign_api_key, latLonGeom.x, latLonGeom.y);
            document.head.appendChild(script);
        }
        ,handleIGNResponse : function(data) {
            var parser = new DOMParser();
            var xmlDoc = parser.parseFromString(data.xml, "text/xml");
            var s = xmlDoc.getElementsByTagName('z');
            if (s.length === 0 || Ext.isEmpty(s[0]) || Ext.isEmpty(s[0].innerHTML)) {
                Ext.Msg.alert('Attention', "Un problème à été rencontré lors de l'appel au service de l'IGN.");
                return;
            }
            Ext.ux.Toast.msg('Information !', 'Cette altitude est fournie par un service de l\'IGN.');
            application.editStation.setAltitude(Math.round(s[0].innerHTML));
        }
        ,setAltitude : function(alti) {
            Ext.getCmp('numberfield-altitude').setValue(alti);
        }
        
        ,changeLabel: function(fieldId, newLabel){
              var label = Ext.DomQuery.select(String.format('label[for="{0}"]', fieldId));
              if (label){
                label[0].childNodes[0].nodeValue = newLabel;
              }
        }
    }
}();
