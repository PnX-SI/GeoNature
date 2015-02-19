/**
 * @class application.stationPanel
 * Class to build a panel in which use will find Station details
 * @extends Ext.Panel
 * @constructor
 * @param {Object} config The configuration options
 */

application.stationPanel = function(config) {

    this.id_station = config.station.id_station;
    this.tbar = ['Informations concernant la station N°'];
    this.loadStation();  
    this.droitsEdition = null;

    /**
     * Property: taxonsStore
     * {Ext.data.GroupingStore}
     */
    this.taxonsStore = new Ext.data.GroupingStore({
        reader: new mapfish.widgets.data.FeatureReader(
            {}, [
                'cd_nom'
                ,'cd_ref'
                ,'nom_complet'
                ,'taxon_saisi'
                ,'nom_valide_complet'
                ,'nom_vern'
                ,'famille'
                ,'id_station'
                ,'herb'
                ,'inf_1m'
                ,'de_1_4m'
                ,'sup_4m'
                ,'protections'
                ,'protection'
                ,{name: 'no_protection', defaultValue: false}
                ,{name: 'noteditable', defaultValue: false}
                ,{name: 'notremovable', defaultValue: false}
                ]
        )
        ,sortInfo:{field: 'nom_complet', direction: "ASC"}
        //,groupField:'categorie'
        ,listeners: {
            load: function(store, records) {
                for (var i = 0, l = records.length; i < l; i++) {
                    // modify some attributes to manage buttons
                    var r = records[i];
                    var show_edit_button = (this.droitsEdition==true||application.user.statuscode >= 3);
                    var show_remove_button = (this.droitsEdition==true||application.user.statuscode >= 3);
                    r.set('noteditable',
                        !show_edit_button
                    );
                    r.set('notremovable',
                        !show_remove_button
                    );
                }
                var count = store.getTotalCount();
                this.taxonsGrid.setTitle(count + " taxon(s)");
                // force the sort since it doesn't seem to work with TriggerEventDecorator
                store.sort('nom_complet');
            }
            ,scope: this
        }
    });

    //Reusable config options here
    Ext.apply(this, config);
    // And Call the superclass to preserve baseclass functionality
    application.stationPanel.superclass.constructor.apply(this, arguments);
};

Ext.extend(application.stationPanel, Ext.Panel,  {
    title: 'chargement ...'
    ,layout: 'border'
    ,defaults: {border: false}
    ,closable: true       
    ,cls: 'station-panel'

    /**
     * APIProperty: map
     * {<OpenLayers.Map>}
     */
    ,map: null

    /**
     * APIProperty: station
     * {Ext.Record}
     */
    ,station: null

    /**
     * APIProperty: layerVector
     * {<OpenLayers.Layer.Vector>}
     */
    ,layerVector: null

    /**
     * APIProperty: layerTreeTip
     * {Ext.Tip}
     */
    ,layerTreeTip: null

    /**
     * APIProperty: toolbar
     * The mapcomponent toolbar
     */
    ,toolbar: false

    ,topToolbarInitializedOnce: false

    ,toolbarInitializedOnce: false
    
    ,validationStatusText: null
    
    ,validateButton: null

    ,modifyStationButton: null

    /**
     * Property: tplStationDescriptionCols
     * The temlates to show the station details
     */
    // TODO : possibly compile those templates
    ,tplStationDescriptionCols: [
        new Ext.XTemplate(
            '<p><b>Station N° :</b> {id_station} du {dateobs}<tpl if="commune"> ({commune}) </tpl></p>'
            ,'<tpl if="info_acces"><p><b>Accès : </b>{info_acces}</p></tpl>'
            ,'<tpl if="observateurs"><p><b>Observateur(s) : </b>{observateurs} </p></tpl>'
            ,'<tpl if="fullreleve"><p><b>Niveau de relevé : </b>{fullreleve} </p></tpl>'
            ,'<tpl if="nom_programme_fs"><p><b>Programme : </b>{nom_programme_fs} <tpl if="id_sophie!=0"> (polygone {id_sophie})</tpl></p></tpl>'
            ,'<tpl if="nom_support"><p><b>Pointage sur : </b>{nom_support} </p></tpl>'   
        )
        ,new Ext.XTemplate(
            '<tpl if="nom_surface"><p><b>Surface : </b>{nom_surface}<tpl if="nom_homogene"> - <b>homogène : </b>{nom_homogene}</tpl></p></tpl>'
            ,'<tpl if="nom_exposition"><p><b>Exposition : </b>{nom_exposition}<tpl if="altitude"><b> - Altitude : </b>{altitude}</tpl></p></tpl>'
            ,'<tpl if="microreliefs"><p><b>Micro-relief(s) : </b>{microreliefs}</tpl>'
            ,'<tpl if="meso_longitudinal"><p><b>Méso-relief amont-aval : </b>{meso_longitudinal}</tpl><tpl if="meso_lateral"> <b>- gauche-droite : </b>{meso_lateral}</p></tpl>'
            ,'<tpl if="canopee!=0"><p><b>Arbre le plus haut : </b>{canopee} m</p></tpl><tpl if="canopee==0"><p><b>Arbre le plus haut :</b> non renseigné</p></tpl>'
        )
        ,new Ext.XTemplate(
            '<p><b>Ligneux hauts : </b>{ligneux_hauts}<tpl if="ligneux_hauts">%</tpl> </p>'
            ,'<p><b>Ligneux bas : </b>{ligneux_bas}<tpl if="ligneux_bas">%</tpl></p>'
            ,'<p><b>Ligneux très bas : </b>{ligneux_tbas}<tpl if="ligneux_tbas">%</tpl></p>'
            ,'<p><b>Herbacés : </b>{herbaces}<tpl if="herbaces">%</tpl></p>'
            ,'<p><b>Mousses : </b>{mousses}<tpl if="mousses">%</tpl></p>'
            ,'<p><b>Litière : </b>{litiere}<tpl if="litiere">%</tpl></p>'
        )
        ,new Ext.XTemplate(
            '<tpl if="date_update"><p><b>Dernière modification :</b> {date_update}</p></tpl>'
            ,'<tpl if="remarques"><p><b>Remarques :</b> {remarques}</p></tpl>'
            ,'<p><a href="{URI}">Lien vers cette fiche</a></p>'
            ,'<tpl if="x_utm"><p><b>Coordonnées UTM :</b> Longitude : {x_utm} - Latitude : {y_utm}</p></tpl>'
            ,'<tpl if="x_l93"><p><b>Coordonnées Lambert 2 :</b> Longitude : {x_l93} - Latitude : {y_l93}</p></tpl>'
            ,'<tpl if="validation==true">'
            ,'<p class="greenflag" title="Cette station et son contenu ont été relus par l\'un des référents"><img src="images/flag_green.png"><b>Cette fiche a été relue par l\'un des référents</b></p></tpl>'
            ,'<tpl if="validation==false">'
            ,'<p class="redflag" title="Cette station et son contenu n\'ont pas encore été relus par l\'un des référents"><img src="images/flag_red.png"><b>Cette fiche n\'a pas encore été relue par l\'un des référents</b></p></tpl>'
        )
    ]

    ,tplTaxonDetail: new Ext.XTemplate(
        '<tpl if="famille"><p><b>famille : </b>{famille}</p></tpl>'
        ,'<tpl if="nom_valide_complet"><p><b>nom valide complet: </b>{nom_valide_complet}</p></tpl>'
        ,'<tpl if="nom_complet"><p><b>nom renseigné : </b>{nom_complet}</p></tpl>'
        ,'<tpl if="taxon_saisi"><p><b>nom saisi : </b>{taxon_saisi}</p></tpl>' 
        ,'<tpl if="nom_vern"><p><b>nom français : </b>{nom_vern}</p></tpl>'
        ,'<tpl if="no_protection==false"><p><b>Réglementation</b></p>'
            ,'<tpl for="protections">'
                ,'<tpl if="url==\'pas de version \u00e0 jour\'">'
                    ,'<p>{texte}</p>'
                ,'</tpl>'
                ,'<tpl if="url!=\'pas de version \u00e0 jour\'">'
                    ,'<p><a href="{url}" target="_blank">{texte}</a></p>'
                ,'</tpl>'
            ,'</tpl>'
        ,'</tpl>'
         
    )

    // private
    ,initComponent : function(){

        this.taxonsGrid = this.getTaxonsGrid();
        this.createMap();

        this.items = [
            this.getNorthRegion()
            ,this.getWestRegion()
            ,this.getCenterRegion()
        ];

        application.stationPanel.superclass.initComponent.call(this);

        this.on('afterlayout', this.createLayer, this);
        this.on('afterlayout', this.createLayerTreeTip, this);
        
    }

    ,getNorthRegion: function() {
        return {
            region:"north",
            height:120,
            split:true,
            bodyStyle:"background-color:#fec5f7",
            layout: 'column',
            autoScroll: true,
            defaults: {
                border: false
            },
            items: [{
                columnWidth: 0.25
                ,id: 'description-col0-' + this.id_station
                ,bodyStyle:"background-color:#fec5f7"
            },{
                columnWidth: 0.30
                ,id: 'description-col1-' + this.id_station
                ,bodyStyle:"background-color:#fec5f7"
            },{
                columnWidth: 0.15
                ,id: 'description-col2-' + this.id_station
                ,bodyStyle:"background-color:#fec5f7"
            },{
                columnWidth: 0.30
                ,id: 'description-col3-' + this.id_station
                ,bodyStyle:"background-color:#fec5f7"
            }]
        }
    }

    ,getWestRegion: function() {
        return {
            region:"west"
            ,xtype: "tabpanel"
            ,width:550
            ,split:true
            ,defaults: {
                border: false
            }
            //,tabPosition: 'bottom'
            ,activeTab: 0
            ,deferredRender: true
            ,items: [
                this.taxonsGrid
            ]
        }
    }

    ,getCenterRegion: function() {

        this.toolbar = new mapfish.widgets.toolbar.Toolbar({
            map: this.map,
            configurable: false
        });

        return {
            region: 'center'
            ,xtype: 'mapcomponent'
            ,id: this.id_station + '-mapcomponent'
            ,map: this.map
            ,tbar: this.toolbar
            ,listeners: {
                render: function() {
                    this.initToolbarItems();
                }
                ,scope: this
            }
        }
    }

    /**
     * Method: initToolbarItems
     * Creates the map toolbar
     */
    ,initToolbarItems: function() {
        if (!this.toolbarInitializedOnce) {
            this.toolbar.addControl(
                new OpenLayers.Control.ZoomToMaxExtent({
                    map: this.map,
                    title: 'Revenir à l\'échelle maximale'
                }), {
                    iconCls: 'zoomfull',
                    toggleGroup: this.id
                }
            );

            application.utils.addSeparator(this.toolbar);

            this.toolbar.addControl(
                new OpenLayers.Control.ZoomBox({
                    title: 'Zoomer'
                }), {
                    iconCls: 'zoomin',
                    toggleGroup: this.id
                }
            );

            this.toolbar.addControl(
                new OpenLayers.Control.ZoomBox({
                    out: true,
                    title: 'Dézoomer'
                }), {
                    iconCls: 'zoomout',
                    toggleGroup: this.id
                }
            );

            this.toolbar.addControl(
                dragPanControl = new OpenLayers.Control.DragPan({
                    title: 'Déplacer la carte'
                    ,isDefault: true
                }), {
                    iconCls: 'pan',
                    toggleGroup: this.id

                }
            );

            application.utils.addSeparator(this.toolbar);

            this.toolbar.add({
                iconCls: 'legend'
                ,id:'station-layertreetip'
                ,enableToggle: true
                ,tooltip: 'Gérer les couches affichées'
                ,handler: function(button) {
                    this.showLayerTreeTip(button.pressed);
                }
                ,scope: this
            });

            this.toolbar.activate();
            this.toolbarInitializedOnce = true;
        }

    }

    /**
     * Method: getTaxonsGrid
     */
    ,getTaxonsGrid: function() {
        var expander = new Ext.grid.RowExpander({
            tpl : this.tplTaxonDetail
        });

        var edition = new Ext.ux.grid.RowActions({
            actions: [{
                iconCls: 'action-edit'
                ,tooltip: 'Modifier ce taxon'
                ,hideIndex: 'noteditable'
            },{
                iconCls: 'action-remove'
                ,tooltip: 'Supprimer ce taxon du relevé'
                ,hideIndex: 'notremovable'
            }]
            ,listeners: {
                action: function (grid, record, action) {
                    switch (action) {
                        case 'action-edit':
                            application.editStation.loadStation(this.id_station,'update',record.data.cd_nom);
                            break;
                        case 'action-remove':
                            Ext.Msg.confirm('Attention'
                                ,'Etes-vous certain de vouloir supprimer ce taxon ?'
                                ,function(btn) {
                                    if (btn == 'yes') {
                                        this.deleteTaxon(record);
                                    }
                                }
                                ,this // scope
                            );
                            break;
                    }
                }
                ,scope: this
            }
            ,header: 'Edition'
            ,fixed: true
            ,autoWidth: false
            ,width: 50
        });
       
        var rowActionsLink = new Ext.ux.grid.RowActions({
            actions: [{
                tooltip: 'Consulter le site INPN concernant ce taxon',
                iconCls: 'action-link'
            }]
            ,listeners: {
                action: function (grid, record, action) {
                    switch (action) {
                        case 'action-link':
                            window.open('http://inpn.mnhn.fr/isb/espece/cd_nom/' + record.data.cd_nom);
                            break;
                    }
                }
            }
            ,fixed: true
            ,autoWidth: false
            ,width: 25
        });
        
        var rowActionsProtection = new Ext.ux.grid.RowActions({
            actions: [{
                tooltip: 'Protection'
                ,iconCls: 'un-validate'
                ,hideIndex: 'no_protection'
            }]
            ,hideMode: 'display'
            ,fixed: true
            ,autoWidth: false
            ,width: 25
        });

        
        var columns = [
            expander,rowActionsLink,rowActionsProtection
            ,{header: "cd_nom", width: 75, sortable: true, dataIndex: 'cd_nom', hidden: true}
            ,{header: "cd_ref", width: 75, sortable: true, dataIndex: 'cd_ref', hidden: true}
            ,{header: "Taxon",width: 125, sortable: true, dataIndex: 'nom_complet',id:'nom_complet'}
            ,{header: "Nom valide complet", width: 125, sortable: true, dataIndex: 'nom_valide_complet', hidden: true}
            ,{header: "Nom français",width: 125, sortable: true, dataIndex: 'nom_vern', hidden: true}
            ,{header: "Nom renseigné", width: 125, sortable: true, dataIndex: 'nom_complet', hidden: true}
            ,{header: "Nom saisi", width: 125, sortable: true, dataIndex: 'taxon_saisi', hidden: true}
            ,{header: "Herbacée", width: 60, sortable: true, dataIndex: 'herb'}
            ,{header: "< à 1m", width: 60, sortable: true, dataIndex: 'inf_1m'}
            ,{header: "1 à 4m", width: 60, sortable: true, dataIndex: 'de_1_4m'}
            ,{header: "> à 4m", width: 60, sortable: true, dataIndex: 'sup_4m'}
            ,{header: "protection", width: 125, sortable: true, dataIndex: 'protection', hidden: true}
        ];

        if (parseInt(application.user.statuscode) >=2) {
                columns.push(
                    edition
                );
        }


        var grid = new Ext.grid.GridPanel({
            title: 'Taxon(s) de la station'
            ,id:'taxon_list_grid'
            ,store: this.taxonsStore
            ,columns: columns
            ,plugins: [expander, rowActionsLink, rowActionsProtection, edition]
            ,stripeRows: true
            ,autoExpandColumn: 'nom_complet'
            ,viewConfig: {
                forceFit: true,
        //      Return CSS class to apply to rows depending upon data values
                getRowClass: function(record, index) {
                    var c = record.get('no_protection');
                    if (c == 'non') {
                        return 'redline';
                    } 
                }
            }
            ,loadMask: true
            ,listeners:{
                rowdblclick:function(grid,rowIndex){
                    var record = grid.getStore().getAt(rowIndex);
                    if(record){
                        application.editStation.loadStation(record.data.id_station,'update',record.data.cd_nom);
                    }
                }
            }
        });

        return grid;
    }

    ,loadStation: function() {
        var reader = new mapfish.widgets.data.FeatureReader({}, [
            'id_station'
            ,'nom_support'
            ,'nom_programme_fs'
            ,'nom_exposition'
            ,'nom_homogene'
            ,'fullreleve'
            ,'validation'
            ,'id_sophie'
            ,'info_acces'
            ,'commune'
            ,'nom_surface'
            ,'meso_longitudinal'
            ,'meso_lateral'
            ,'canopee'
            ,'ligneux_hauts'
            ,'ligneux_bas'
            ,'ligneux_tbas'
            ,'herbaces'
            ,'mousses'
            ,'litiere'
            ,'altitude'
            ,'remarques'
            ,'pdop'
            ,'observateurs'
            ,'ids_observateurs'
            ,'microreliefs'
            ,'nb_taxons'
            ,'x_utm'
            ,'y_utm'
            ,'x_l93'
            ,'y_l93'
            ,{name:'dateobs', dateFormat:'d/m/Y'}
            ,{name:'date_insert', dateFormat:'d/m/Y'}
            ,{name:'date_update', dateFormat:'d/m/Y'}
            ,'URI'
        ]);

        Ext.Ajax.request({
           url: ['station/get', this.id_station].join('/')
           ,success: function(response) {
                var json = Ext.util.JSON.decode(response.responseText);
                var format = new OpenLayers.Format.GeoJSON();
                var features = format.read(json);
                var record = reader.readRecords(features).records[0];
                this.station = record.data;
                this.loadStationDetails();
                this.droitsEdition = this.userIsAutor(this.station.ids_observateurs);
                this.updateTopToolbar();
                if (application.user.statuscode > 1) {
                    this.handleValidation();
                }                
           }
           ,failure:application.checklog 
           // ,failure:alert('toto')
           ,scope: this
           ,params: {
                format: 'geoJSON'
            }
        });
    }

    /**
     * Method: createProtocol
     *
     */
    ,createProtocol: function() {
        var protocol = new mapfish.Protocol.MapFish({
            'url': ['station/gettaxons', this.id_station].join('/')
        });

       return new mapfish.Protocol.TriggerEventDecorator({
            protocol: protocol
            ,eventListeners: {
                crudtriggered: function() {
                    this.taxonsGrid.loadMask.show();
                }
                ,crudfinished: function(response) {
                    if(response.features!=null){
                        if (response.features.length == 0) {
                            this.taxonsGrid.loadMask.hide();
                            this.taxonsGrid.setTitle("Aucun taxon");
                        }
                        //on limit le zoom à 6
                        var zoomLevel = this.map.getZoomForExtent(this.station.feature.geometry.getBounds());
                        var centerGeom = this.station.feature.geometry.getBounds().getCenterLonLat();
                        if (zoomLevel > 6){zoomLevel = 6;}
                        this.map.setCenter(centerGeom,zoomLevel);
                        this.map.div.style.visibility = 'visible';
                    }
                    else{
                        application.checklog();
                        }
                }
               ,scope: this
            }
        });
    }

    /**
     * Method: createLayer
     * Creates the vector layer
     *
     * Return
     * <OpenLayers.Layer.Vector>
     */
    ,createLayer: function() {
        var styleMap = new OpenLayers.StyleMap({
            'default': {
                fillColor: "red"
                ,strokeColor: "red"
                ,cursor: "pointer"
                ,fillOpacity: 0
                ,strokeOpacity: 1
                ,strokeWidth: 3
                ,pointRadius: 8
            }
            ,select : {
                fillColor: "blue"
                ,strokeColor: "red"
                ,cursor: "pointer"
                ,fillOpacity: 0.5
                ,strokeOpacity: 1
                ,strokeWidth: 3
                ,graphicName: 'circle'
                ,pointRadius: 8
            }
        });

        var vector = new OpenLayers.Layer.Vector(
            "vector"
            ,{
                protocol: this.createProtocol()
                ,strategies: [
                    new mapfish.Strategy.ProtocolListener({append: false})
                ]
                ,styleMap: styleMap
            }
        );

        this.map.addLayer(vector);

        var selectControl = new OpenLayers.Control.SelectFeature([vector], {
            multiple: false
        });
        var layerStoreMediator = new mapfish.widgets.data.LayerStoreMediator({
            store: this.taxonsStore,
            layer: vector
        });
        var gridRowFeatureMediator = new mapfish.widgets.data.GridRowFeatureMediator({
            grid: this.taxonsGrid,
            selectControl: selectControl
        });

        this.map.addControl(selectControl);
        selectControl.activate();

        // remove afterlayout listener
        this.un('afterlayout', this.createLayer, this);

        this.layerVector = vector;

        // load the features the first time
        this.layerVector.protocol.read({});
    }

    /**
     * Method: createMap
     * Creates the map
     *
     * Return
     * <OpenLayers.Map>
     */
    ,createMap:function() {
        this.map = application.createMap();
        this.map.getLayersByName('overlay')[0].mergeNewParams({
          id_station:this.id_station
        });
    }

    /**
     * APIMethod: refreshTaxons
     * Refreshes taxons, ie. calls read on the vector layer protocol,
     *      refreshes the WMS layer, etc..
     * Can be called by the editStation window.
     */
    ,refreshTaxons: function() {
        // this.taxonsStore.reload();
        // Ext.getCmp('store-station-search').reload();
        this.layerVector.protocol.read({});
        // redraw the WMS layer (true to force the redraw)
        this.map.getLayersByName('overlay')[0].redraw(true);
    }

    /**
     * Method: deleteTaxon
     * Delete a Taxon
     */
    ,deleteTaxon: function(record) {
        Ext.Ajax.request({
            url: 'station/deletetaxon'
            ,method: 'POST'
            ,params: {
                cd_nom: record.data.cd_nom
                ,id_station: this.id_station
            }
            ,success: function(request) {
                var result = Ext.decode(request.responseText);
                if (result.success) {
                    this.refreshTaxons();
                } else {
                    OpenLayers.Console.error("une erreur s'est produite !");
                }
            }
            ,failure: application.checklog
            ,scope: this
        });
    }

    /**
     * Refreshes stations, ie. refreshes the WMS layer, etc..
     * Can be called by the editStation window.
     */
    ,refreshStation: function() {
        // redraw the WMS layer (true to force the redraw)
        this.map.getLayersByName('overlay')[0].redraw(true);
        this.loadStation();
    }
    
    /**
     * Method: validateStation
     * Validates or unvalidates a station
     * Only administrator should be able to do this
     */
    ,validateStation: function() {
        // Basic request
        Ext.Ajax.request({
            url: 'station/validate'
            ,method: 'POST'
            ,params: {
                id_station: this.id_station
            }
            ,success: function(request) {
                var result = Ext.decode(request.responseText);
                if (result.success) {
                    this.refreshStation();
                    application.search.refreshStations();
                } else {
                    OpenLayers.Console.error("une erreur s'est produite !");
                }
            }
            ,failure: application.checklog
            ,scope: this
        });
    }

    /**
     * Method: createLayerTreeTip
     * Create the layer tree tip
     */
    ,createLayerTreeTip: function() {
        this.layerTreeTip = application.createLayerWindow(this.map);
        this.layerTreeTip.render(Ext.getCmp(this.id_station + '-mapcomponent').body);

        this.layerTreeTip.show();

        this.layerTreeTip.getEl().alignTo(
            Ext.getCmp(this.id_station + '-mapcomponent').body,
            "tl-tl",
            [5, 5]
        );
        this.layerTreeTip.hide();
        //virer les wms de toutes les zp
        // Ext.getCmp('layer-tree-tip').root.findChild('layerNames','overlay:zp_pasrelue').getUI().toggleCheck(false);
        // Ext.getCmp('layer-tree-tip').root.findChild('layerNames','overlay:zp_relue').getUI().toggleCheck(false);
    }

    /**
     * Method: showLayerTreeTip
     * Shows or hide the layer tree tip
     */
    ,showLayerTreeTip: function(show) {
        this.layerTreeTip.setVisible(show);
    }

    /**
     * Method: loadStationDetails
     */
    ,loadStationDetails: function() {
        for (var i = 0; i <= 3; i++) {
            var el = Ext.getCmp('description-col' + i + '-' + this.id_station);
            var tpl = eval(this.tplStationDescriptionCols[i]);
            el.body.update(tpl.apply(this.station));
        }
        this.find('region', 'north')[0].doLayout();

        this.setTitle('N°' +this.station.id_station);
    }
    
    /**
     * Method: userIsAutor
     * Test si l'utilisateur logué fait parti des auteurs du relevé
     */
    ,userIsAutor: function(ids_observateurs) {
        var test = false;
        var reg = new RegExp("[,]+","g");
        var mesIds = ids_observateurs.split(reg);
        for (var i=0, l = mesIds.length; i < l; i++) {
            if(mesIds[i]==application.user.id_role){test=true;}
        }
        return test;
    }

    /**
     * Method: updateTopToolbar
     * Updates the top toolbar with the station name, and the buttons For validation
     */
    ,updateTopToolbar: function() {
        var tbar = this.getTopToolbar();
        if (!this.topToolbarInitializedOnce) {
            tbar.add({xtype: 'tbtext', text: this.station.id_station+' du '+this.station.dateobs});
            tbar.add('->');

            if(application.user.statuscode > 1) {
                if(this.droitsEdition==true||application.user.statuscode > 3){
                    this.validateButton = new Ext.Button({
                        iconCls: '-'  // this should be managed in handleValidation
                        ,text: '-'   // this should be managed in handleValidation
                        ,disabled: false
                        ,handler: function() {
                            this.validateStation();
                        }
                        ,scope: this
                    });
                    tbar.add(this.validateButton);
                }
                if(this.droitsEdition==true||application.user.statuscode >= 3){
                    this.modifyStationButton = new Ext.Button({
                        iconCls: 'edit'
                        ,text: 'Modifier la station'
                        ,disabled: false
                        ,handler: function() {
                            application.editStation.loadStation(this.id_station,'update',null);
                        }
                        ,scope: this
                    });
                    tbar.add(this.modifyStationButton);
                    this.deleteStationButton = new Ext.Button({
                        iconCls: 'remove'
                        ,text: 'Supprimer la station'
                        ,disabled: false
                        ,handler: function() {
                            Ext.Msg.confirm('Attention'
                                ,"Etes-vous certain de vouloir supprimer cette station ? \n" +
                                 "Attention cela supprimera aussi toutes les observations qu'elle contient."
                                ,function(btn) {
                                    if (btn == 'yes') {
                                        this.deleteStation();
                                    }
                                }
                                ,this // scope
                            );
                        }
                        ,scope: this
                    });
                    tbar.add(this.deleteStationButton);
                }
            }

            // var printAction = new mapfish.ux.widgets.print.PrintAction({ // TODO add a "var"
                // map: this.map
                // ,iconCls: 'print'
                // ,configUrl: "print/info"
                // ,stationPanel: this
                // ,overrides: {'vector': {visibility: false}}
            // });
            // tbar.add(printAction);

            /*
            tbar.add({
                text:"Rechercher une autre ZP",
                iconCls: 'back_to_search',
                handler: function () {
                    application.layout.tabPanel.setActiveTab(0);
                }
            });*/
            this.topToolbarInitializedOnce = true;
        }
        else{Ext.getCmp('station-'+this.station.id_station).getTopToolbar().getEl().dom.children[0].children[0].children[0].children[0].textContent = 'Informations concernant la station N° '+this.station.id_station+' du '+this.station.dateobs;}
        tbar.doLayout();
    }
    
    /**
     * Method: handleValidation
     */
    ,handleValidation: function() {
        if (application.user.statuscode >= 3) {
            
            this.validateButton.show();
            if (this.station.validation) {
                this.validateButton.setIconClass('notvalidated');
                this.validateButton.setText('Marquer comme non relue');
            } else {
                this.validateButton.setIconClass('validated');
                this.validateButton.setText('Marquer comme relue');
            }
        } 
    }
    
    /**
     * Method: deleteStation
     * Calls the service to delete the station from database
     */
    ,deleteStation: function() {
        // Basic request
        Ext.Ajax.request({
            url: 'station/delete'
            ,method: 'POST'
            ,params: {
                id_station: this.id_station
            }
            ,success: function(request) {
                var result = Ext.decode(request.responseText);
                if (result.success) {
                    application.layout.tabPanel.remove(this);
                    application.search.refreshStations();
                } else {
                    OpenLayers.Console.error("une erreur s'est produite !");
                }
            }
            ,failure: application.checklog
            ,scope: this
        });
    }

});
