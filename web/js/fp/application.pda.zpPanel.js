/**
 * @class application.zpPanel
 * Class to build a panel in which use will find zp details
 * @extends Ext.Panel
 * @constructor
 * @param {Object} config The configuration options
 */

application.zpPanel = function(config) {

    this.zp = config.zp;
    this.indexzp = config.zp.data.indexzp;
    this.tbar = ['Informations concernant la zone  de prospection de '];
    this.loadZp();
    this.droitsEdition = null;

    /**
     * Property: apsStore
     * {Ext.data.GroupingStore}
     */
    this.apsStore = new Ext.data.GroupingStore({
        reader: new mapfish.widgets.data.FeatureReader(
            {}, [
                'indexap'
                ,'codepheno'
                ,'indexzp'
                ,'pdop'
                ,'altitude'
                ,'edition'
                ,'surface'
                ,'frequencemethodo'
                ,'frequenceap'
                ,'topo_valid'
                ,{name:'date_insert', dateFormat:'d/m/Y'}
                ,{name:'date_update', dateFormat:'d/m/Y'}
                ,'phenologie'
                ,'perturbations'
                ,'physionomies'
                ,'objets'
                ,'observateurs'
                ,'remarques'
                ,{name: 'validated', defaultValue: false}
                ,{name: 'notvalidated', defaultValue: false}
                ,{name: 'noteditable', defaultValue: false}
                ,{name: 'notremovable', defaultValue: false}
            ]
        )
        ,sortInfo:{field: 'frequenceap', direction: "ASC"}
        //,groupField:'categorie'
        ,listeners: {
            load: function(store, records) {
                for (var i = 0, l = records.length; i < l; i++) {
                    // modify some attributes to manage validation buttons
                    var r = records[i];
                    var show_edit_button = (this.droitsEdition==true||application.user.statuscode > 3);
                    var show_remove_button = (this.droitsEdition==true||application.user.statuscode > 3);
                    r.set('noteditable',
                        !show_edit_button
                    );
                    r.set('notremovable',
                        !show_remove_button
                    );
                    if (!r.get('topo_valid')) {
                        r.set('notvalidated', 'notvalidated');
                    } else {                   
                        r.set('validated', 'validated');
                    }
                }
                var count = store.getTotalCount();
                this.apsGrid.setTitle(count + " aire(s) de présence");

                // force the sort since it doesn't seem to work with TriggerEventDecorator
                store.sort('frequenceap');
            }
            ,scope: this
        }
    });

    //Reusable config options here
    Ext.apply(this, config);
    // And Call the superclass to preserve baseclass functionality
    application.zpPanel.superclass.constructor.apply(this, arguments);
};

Ext.extend(application.zpPanel, Ext.Panel,  {
    title: 'chargement ...'
    ,layout: 'border'
    ,defaults: {border: false}
    ,closable: true       
    ,cls: 'zp-panel'

    /**
     * APIProperty: map
     * {<OpenLayers.Map>}
     */
    ,map: null

    /**
     * APIProperty: zp
     * {Ext.Record}
     */
    ,zp: null

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

    ,modifyZpButton: null

    /**
     * Property: tplZpDescriptionCols
     * The temlates to show the zp details
     */
    // TODO : possibly compile those templates
    ,tplZpDescriptionCols: [
        new Ext.XTemplate(
            '<p><b>Espèce :</b> {taxon_latin}</p>'
            ,'<tpl if="observateurs">'
            ,'<p><b>Liste des observateurs : </b>{observateurs} </p></tpl> '
            ,'<tpl if="communezp"><p><b>commune : </b>{communezp} </p></tpl> '
            ,'<p><a href="{URI}">Lien permanent vers la fiche</a></p>'
        )
        ,new Ext.XTemplate(
            '<p><b>Date du relevé :</b> {dateobs}</p>'
            ,'<p><b>Dernière modification :</b> {date_update}</p>'
            ,'<p><b>Organisme source :</b> {nom_organisme}</p>'
        )
        ,new Ext.XTemplate(
            '<tpl if="topo_valid==false">'
            ,'<p class="redtext" title="Le contour de la zone de prospection a mal été dessiné. Vous pouvez la corriger si vous disposez des droits nécessaires"><b>Attention ! Topologie non valide</b></p></tpl>'
            ,'<tpl if="validation==true">'
            ,'<p class="greenflag" title="Cette zone de prospection et son contenu ont été relus par l\'un des référents"><img src="images/flag_green.png"><b>Cette fiche a été relue par l\'un des référents</b></p></tpl>'
            ,'<tpl if="validation==false">'
            ,'<p class="redflag" title="Cette zone de prospection et son contenu n\'ont pas encore été relus par l\'un des référents"><img src="images/flag_red.png"><b>Cette fiche n\'a pas encore été relue par l\'un des référents</b></p></tpl>'
        )
    ]

    ,tplApDetail: new Ext.XTemplate(
        '<tpl if="topo_valid==false">'
        ,'<p class="redtext"><b>Attention ! Topologie non valide</b></p></tpl>'
        ,'<p><b>Phénologie:</b> {phenologie}</p>'
        ,'<p><b>Méthode de calcul de la fréquence :</b> {frequencemethodo}</p>'
        ,'<p><b>Dernière modification :</b> {date_update}</p>'
        ,'<tpl if="objets">'
        ,'<p><b>Objets comptés : </b>{objets} </tpl></p>'
        ,'<tpl if="perturbations">'
        ,'<p><b>Liste des perturbations :</b> {perturbations}</tpl></p>'
        ,'<tpl if="physionomies">'
        ,'<p><b>Physionomies :</b> {physionomies}</tpl></p>'
        ,'<p><b>Altitude moyenne:</b> {altitude}</p>'
        ,'<p><b>Précision GPS (pdop) :</b> {pdop}</p>'
        ,'<tpl if="remarques">'
        ,'<p><b>Remarques :</b> {remarques}</tpl></p>'
    )

    // private
    ,initComponent : function(){

        this.apsGrid = this.getApsGrid();
        this.createMap();

        this.items = [
            this.getNorthRegion()
            ,this.getWestRegion()
            ,this.getCenterRegion()
        ];

        application.zpPanel.superclass.initComponent.call(this);

        this.on('afterlayout', this.createLayer, this);
        this.on('afterlayout', this.createLayerTreeTip, this);
        
    }

    ,getNorthRegion: function() {
        return {
            region:"north",
            height:90,
            split:true,
            bodyStyle:"background-color:#ffffce",
            layout: 'column',
            autoScroll: true,
            defaults: {
                border: false
            },
            items: [{
                columnWidth: 0.4
                ,id: 'description-col0-' + this.indexzp
                ,bodyStyle:"background-color:#ffffce"
            },{
                columnWidth: 0.3
                ,id: 'description-col1-' + this.indexzp
                ,bodyStyle:"background-color:#ffffce"
            },{
                columnWidth: 0.3
                ,id: 'description-col2-' + this.indexzp
                ,bodyStyle:"background-color:#ffffce"
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
                this.apsGrid
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
            ,id: this.indexzp + '-mapcomponent'
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
                ,id:'zp-layertreetip'
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
     * Method: getApsGrid
     */
    ,getApsGrid: function() {
        var expander = new Ext.grid.RowExpander({
            tpl : this.tplApDetail
        });

        var topologie = new Ext.ux.grid.RowActions({
            actions: [{
                iconIndex: 'notvalidated'
                ,tooltip: 'Topologie non valide'
                ,hideIndex: 'validated'
            },{
                iconIndex: 'validated'
                ,tooltip: 'Topologie valide'
                ,hideIndex: 'notvalidated'
            }]
            ,hideMode: 'display'
            ,header: 'Topologie'
            ,fixed: true
            ,autoWidth: false
            ,width: 55
        });

        var edition = new Ext.ux.grid.RowActions({
            actions: [{
                iconCls: 'action-edit'
                ,tooltip: 'Modifier l\'aire de présence'
                ,hideIndex: 'noteditable'
            },{
                iconCls: 'action-remove'
                ,tooltip: 'Supprimer l\'aire de présence'
                ,hideIndex: 'notremovable'
            }]
            ,listeners: {
                action: function (grid, record, action) {
                    switch (action) {
                        case 'action-edit':
                            application.editAp.loadAp(record.data.indexap, record,'update');
                            break;
                        case 'action-remove':

                            Ext.Msg.confirm('Attention'
                                ,'Etes-vous certain de vouloir supprimer cette aire de présence ?'
                                ,function(btn) {
                                    if (btn == 'yes') {
                                        this.deleteAp(record);
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
        
        var columns = [
            expander
            ,{header: "Indexap", width: 75, sortable: true, dataIndex: 'indexap', hidden: true}
            ,{id:'frequenceap',width: 55,header: "Fréquence en %", sortable: true, dataIndex: 'frequenceap', renderer:function(val,meta,record){return (val==0)?'0':val;}}
            ,{header: "Surface en m²", width: 80, sortable: true, dataIndex: 'surface'}
        ];
        if (parseInt(application.user.statuscode) >=2) {
            columns.push(
                //{header: "Diffusion", width: 40, dataIndex: 'diffusion'}
                topologie
            );
        }
        if (parseInt(application.user.statuscode) >= 2) {
            columns.push(
                edition
            );
        }
        
        toolbarItems =  new Ext.Toolbar({items:[]});
        if(application.user.statuscode >= 2){
            var addApButton = new Ext.Button({
                iconCls: 'add'
                ,text: 'Nouvelle aire de présence'
                ,disabled: false
                ,handler: function() {
                    application.editAp.loadAp(null,this.zp,'add',this.zp.data.feature.geometry.bounds);
                }
                ,scope: this
            });
            toolbarItems.add(addApButton);
        }


        var grid = new Ext.grid.GridPanel({
            title: 'Aire de présence de la zone de prospection'
            ,id:'ap_list_grid'
            ,store: this.apsStore
            ,columns: columns
            ,plugins: [expander, topologie, edition]
            /*,view: new Ext.grid.GroupingView({
                forceFit:true,
                groupTextTpl: '{text} ({[values.rs.length]} {[values.rs.length > 1 ? "aires de présence" : "aires de présence"]})'
            })*/
            ,stripeRows: true
            ,autoExpandColumn: 'frequenceap'
            ,loadMask: true
            ,tbar: toolbarItems
            ,listeners:{
                rowdblclick:function(grid,rowIndex){
                    var record = grid.getStore().getAt(rowIndex);
                    if(record){
                        application.editAp.loadAp(record.data.indexap,record,'update');
                    }
                }
            }
        });

        return grid;
    }

    ,loadZp: function() {
        var reader = new mapfish.widgets.data.FeatureReader({}, [
            'indexzp'
            ,'taxon_latin'
            ,'taxon_francais'
            ,'observateurs'
            ,'ids_observateurs'
            ,'id_organisme'
            ,'nom_organisme'
            ,'nb_ap'
            ,'nb_obs'
            ,'topo_valid'
            ,'communezp'
            ,'objets_a_compter'
            ,{name:'dateobs', dateFormat:'d/m/Y'}
            ,{name:'date_insert', dateFormat:'d/m/Y'}
            ,{name:'date_update', dateFormat:'d/m/Y'}
            ,'validation'
            ,'URI'
        ]);

        Ext.Ajax.request({
           url: ['zp/get', this.indexzp].join('/')
           ,success: function(response) {
                var json = Ext.util.JSON.decode(response.responseText);
                var format = new OpenLayers.Format.GeoJSON();
                var features = format.read(json);
                var record = reader.readRecords(features).records[0];
                this.zp = record;
                this.loadZpDetails();
                this.droitsEdition = this.userIsAutor(this.zp.data.ids_observateurs)||this.userIsReferent(this.zp.data.id_organisme);
                this.updateTopToolbar();
                if (application.user.statuscode > 1) {
                    this.handleValidation();
                }
           }
           ,failure:application.checklog 
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
            'url': ['ap/get', this.indexzp].join('/')
        });

       return new mapfish.Protocol.TriggerEventDecorator({
            protocol: protocol
            ,eventListeners: {
                crudtriggered: function() {
                    this.apsGrid.loadMask.show();
                }
                ,crudfinished: function(response) {
                    if(response.features!=null){
                        if (response.features.length == 0) {
                            this.apsGrid.loadMask.hide();
                            this.apsGrid.setTitle("Aucune aire de présence");
                        }
                        //on limit le zoom à 9
                        var zoomLevel = this.map.getZoomForExtent(this.zp.data.feature.geometry.getBounds());
                        var centerGeom = this.zp.data.feature.geometry.getBounds().getCenterLonLat();
                        if (zoomLevel > 9){zoomLevel = 9;}
                        this.map.setCenter(centerGeom,zoomLevel);
                        this.map.div.style.visibility = 'visible';
                    }
                    else{application.checklog();}
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
                ,strokeOpacity: 0
                ,strokeWidth: 3
                ,pointRadius: 8
            }
            ,select : {
                fillColor: "blue"
                ,strokeColor: "blue"
                ,cursor: "pointer"
                ,fillOpacity: 0.5
                ,strokeOpacity: 1
                ,strokeWidth: 2
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
            store: this.apsStore,
            layer: vector
        });
        var gridRowFeatureMediator = new mapfish.widgets.data.GridRowFeatureMediator({
            grid: this.apsGrid,
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
          indexzp:this.indexzp
        });
    }

    /**
     * APIMethod: refreshAps
     * Refreshes aps, ie. calls read on the vector layer protocol,
     *      refreshes the WMS layer, etc..
     * Can be called by the editAp window.
     */
    ,refreshAps: function() {
        this.layerVector.protocol.read({});
        // redraw the WMS layer (true to force the redraw)
        this.map.getLayersByName('overlay')[0].redraw(true);
    }



    /**
     * Method: validateZp
     * Validates or unvalidates a zp
     * Only administrator should be able to do this
     */
    ,validateZp: function() {
        // Basic request
        Ext.Ajax.request({
            url: 'zp/validate'
            ,method: 'POST'
            ,params: {
                indexzp: this.indexzp
            }
            ,success: function(request) {
                var result = Ext.decode(request.responseText);
                if (result.success) {
                    this.refreshZp();
                    application.search.refreshZps();
                } else {
                    OpenLayers.Console.error("une erreur s'est produite !");
                }
            }
            ,failure: application.checklog
            ,scope: this
        });
    }


    /**
     * Method: deleteAp
     * Deletes a zp
     */
    ,deleteAp: function(record) {
        Ext.Ajax.request({
            url: 'ap/delete'
            ,method: 'POST'
            ,params: {
                indexap: record.data.indexap
            }
            ,success: function(request) {
                var result = Ext.decode(request.responseText);
                if (result.success) {
                    this.refreshAps();
                    application.search.refreshZps();
                } else {
                    OpenLayers.Console.error("une erreur s'est produite !");
                }
            }
            ,failure: application.checklog
            ,scope: this
        });
    }

    /**
     * Refreshes zps, ie. refreshes the WMS layer, etc..
     * Can be called by the editZp window.
     */
    ,refreshZp: function() {
        // redraw the WMS layer (true to force the redraw)
        this.map.getLayersByName('overlay')[0].redraw(true);
        this.loadZp();
    }

    /**
     * Method: createLayerTreeTip
     * Create the layer tree tip
     */
    ,createLayerTreeTip: function() {
        this.layerTreeTip = application.createLayerWindow(this.map);
        this.layerTreeTip.render(Ext.getCmp(this.indexzp + '-mapcomponent').body);

        this.layerTreeTip.show();

        this.layerTreeTip.getEl().alignTo(
            Ext.getCmp(this.indexzp + '-mapcomponent').body,
            "tl-tl",
            [5, 5]
        );
        this.layerTreeTip.hide();
        //virer les wms de toutes les zp
        Ext.getCmp('layer-tree-tip').root.findChild('layerNames','overlay:zp_pasrelue').getUI().toggleCheck(false);
        Ext.getCmp('layer-tree-tip').root.findChild('layerNames','overlay:zp_relue').getUI().toggleCheck(false);
    }
    
    /**
     * Method: showLayerTreeTip
     * Shows or hide the layer tree tip
     */
    ,showLayerTreeTip: function(show) {
        this.layerTreeTip.setVisible(show);
    }

    /**
     * Method: loadZpDetails
     */
    ,loadZpDetails: function() {
        for (var i = 0; i <= 2; i++) {
            var el = Ext.getCmp('description-col' + i + '-' + this.indexzp);
            var tpl = eval(this.tplZpDescriptionCols[i]);
            el.body.update(tpl.apply(this.zp.data));
        }
        this.find('region', 'north')[0].doLayout();

        this.setTitle(this.zp.data.taxon_latin);
    }
    
    /**
     * Method: userIsAutor
     * Test si l'utilisateur logué fait parti des auteurs de la prospection
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
     * Method: userIsReferent
     * Test si l'utilisateur logué est un référent de l'organisme source de la zp
     */
    ,userIsReferent: function(id_organisme) {
        var test = false;
        if(application.user.statuscode>=3){
            if(id_organisme==application.user.id_organisme){test=true;}
        }
        return test;
    }

    /**
     * Method: updateTopToolbar
     * Updates the top toolbar with the zp name, and the buttons for notation/validation
     */
    ,updateTopToolbar: function() {
        var tbar = this.getTopToolbar();
        if (!this.topToolbarInitializedOnce) {
            tbar.add({xtype: 'tbtext', text: this.zp.data.taxon_latin+' du '+this.zp.data.dateobs});
            tbar.add('->');

            if(application.user.statuscode > 1) {                
                if(this.droitsEdition==true||application.user.statuscode > 3){
                    this.validateButton = new Ext.Button({
                        iconCls: '-'  // this should be managed in handleValidation
                        ,text: '-'   // this should be managed in handleValidation
                        ,disabled: false
                        ,handler: function() {
                            this.validateZp();
                        }
                        ,scope: this
                    });
                    tbar.add(this.validateButton);
                }
                if(this.droitsEdition==true||application.user.statuscode > 3){
                    this.modifyZpButton = new Ext.Button({
                        iconCls: 'edit'
                        ,text: 'Modifier la ZP'
                        ,disabled: false
                        ,handler: function() {
                            application.editZp.loadZp(this.indexzp,'update');
                        }
                        ,scope: this
                    });
                    tbar.add(this.modifyZpButton);
                    this.deleteZpButton = new Ext.Button({
                        iconCls: 'remove'
                        ,text: 'Supprimer la ZP'
                        ,disabled: false
                        ,handler: function() {
                            Ext.Msg.confirm('Attention'
                                ,"Etes-vous certain de vouloir supprimer cette zone de prospection ? \n" +
                                 "Attention cela supprimera aussi les aires de présence qu'elle contient"
                                ,function(btn) {
                                    if (btn == 'yes') {
                                        this.deleteZp();
                                    }
                                }
                                ,this // scope
                            );
                        }
                        ,scope: this
                    });
                    tbar.add(this.deleteZpButton);
                }
            }

            var printAction = new mapfish.ux.widgets.print.PrintAction({ // TODO add a "var"
                map: this.map
                ,iconCls: 'print'
                ,configUrl: "print/info"
                ,zpPanel: this
                ,overrides: {'vector': {visibility: false}}
            });
            tbar.add(printAction);

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
        else{Ext.getCmp('zp-'+this.zp.data.indexzp).getTopToolbar().getEl().dom.children[0].children[0].children[0].children[0].textContent = 'Informations concernant la zone  de prospection de '+this.zp.data.taxon_latin+' du '+this.zp.data.dateobs;}
        tbar.doLayout();
    }
   

    /**
     * Method: handleValidation
     */
    ,handleValidation: function() {
        if (application.user.statuscode >= 3) {
            
            this.validateButton.show();
            if (this.zp.data.validation) {
                this.validateButton.setIconClass('notvalidated');
                this.validateButton.setText('Marquer comme non relue');
            } else {
                this.validateButton.setIconClass('validated');
                this.validateButton.setText('Marquer comme relue');
            }
        } 
    }

    /**
     * Method: deleteZp
     * Calls the service to delete the zp from database
     */
    ,deleteZp: function() {
        // Basic request
        Ext.Ajax.request({
            url: 'zp/delete'
            ,method: 'POST'
            ,params: {
                indexzp: this.indexzp
            }
            ,success: function(request) {
                var result = Ext.decode(request.responseText);
                if (result.success) {
                    application.layout.tabPanel.remove(this);
                    application.search.refreshZps();
                } else {
                    OpenLayers.Console.error("une erreur s'est produite !");
                }
            }
            ,failure: application.checklog
            ,scope: this
        });
    }

});