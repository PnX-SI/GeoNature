/**
 * @class Ext.ux.GpsLocation
 * Fenêtre pour le positionnement à partir de coordonnées fournies (GPS par exemple) 
 * Gil DELUERMOZ 2014
 * @singleton
 */
Ext.ux.GpsLocation = function() {

    // var userProjection = new OpenLayers.Projection("EPSG:32622"); // si besoin de définition manuelle dans ce fichier
    // variables définies dans le config.js
    var userProjection = gps_user_projection; 
    var fuseau = '';
    var zone = '';
    var consigneFuseau = '';
    var consigneExemple = '';
    var xmin = x_min;
    var xmax = x_max;
    var ymin = y_min;
    var ymax = y_max;
    var xex = x_exemple;
    var yex = y_exemple;
    var pnNameLong = pn_name_long;
    if (userProjection.proj.projName=='utm'){
        fuseau = userProjection.proj.zone;
        zone = fuseau;
        consigneFuseau = ', fuseau '+fuseau;
        consigneExemple = 'fuseau '+fuseau+' - ';  
    }
    var msgInfo = 'Les coordonnés doivent être en '+userProjection.proj.title+'('+userProjection.projCode+').<br/>Exemple '+consigneExemple+': X : '+xex+'   Y : '+yex+''
    
    var submitFormGps = function(layer, longitude, latitude, mapProjection, userProjection) {
        if(Ext.getCmp('form-gps-fiche').getForm().isValid()){
            // création du point et reprojection grace à proj4js;
            //La lib pro4js est nécessaire
            //il faut aussi créer les defs comme par exemple EPSG32622.js dans un répertoire proj4js/defs
            //Les 2 projections nécessaires pour le transform sont définies au moment de la création de la fenêtre GSP sinon il y a un pb de timeout et la reprojection n'a pas le temps de se faire ???
            var features = [];
            var projSource = userProjection;
            // alert ('le temps d\'initialisation des projections ou de proj4 ???');
            var mageometry = new OpenLayers.Geometry.Point(longitude, latitude);
            OpenLayers.Projection.transform(mageometry,projSource,mapProjection);
            var mafeature = new OpenLayers.Feature.Vector(mageometry);
            features.push(mafeature);
            map.setCenter(new OpenLayers.LonLat(mageometry.x, mageometry.y),15); //on centre et on zoome avant d'ajouter le point sinon ajout impossible si echelle de zoom insuffisante voir events.on('featureadded'...
            layer.addFeatures(features);
            layer.redraw();
            Ext.getCmp('window-gps').destroy();
        }
        else{
            Ext.Msg.alert('Attention', 'Une information est mal saisie ou n\'est pas valide.</br>Vous devez la corriger avant de poursuivre.');
        }
    };
    
    return{
        initGpsWindow : function(layer) {
            var mapProjection = map.getProjectionObject();
                        
            return new Ext.Window({
                id:'window-gps'
                ,layout:'border'
                ,height:250
                ,width: 400
                ,closeAction:'hide'
                ,autoScroll:true
                ,modal: true
                ,plain: true
                ,split: true
                ,buttons: [{
                    text:'Positionner'
                    ,id:'gps-afficher-button'
                    ,handler: function(){
                        var longitude, latitude;
                        // zone = Ext.getCmp('gps-fiche-zone').getValue();
                        longitude = Ext.getCmp('gps-fiche-longitude').getValue();
                        latitude = Ext.getCmp('gps-fiche-latitude').getValue();
                        submitFormGps(layer, longitude, latitude, mapProjection, userProjection);   
                    }
                },{
                    text: 'Annuler et fermer'
                    ,handler: function(){
                        Ext.getCmp('window-gps').destroy();
                        Ext.ux.Toast.msg('Annulation !', 'Aucun point n\'a été positionné.');
                    }
                }]
                ,items: [{
                    id:'form-gps-fiche'
                    ,xtype: 'form'
                    ,title: 'Positionnement d\'un point à partir de coordonnées fournies'
                    ,region: 'center'
                    ,labelWidth: 100 // label settings here cascade unless overridden
                    ,frame:true
                    ,border:false
                    ,split: false
                    ,autoScroll:false
                    ,monitorValid:true
                    ,bodyStyle:'padding:5px 5px 0'
                    ,width: 350
                    ,defaultType: 'numberfield'
                    ,items: [
                    {
                        id: 'gps-fiche-longitude'
                        ,xtype: 'numberfield'
                        ,allowDecimals :true
                        ,decimalPrecision:6
                        ,decimalSeparator:'.'
                        ,allowNegative: true
                        ,disabled:false
                        ,fieldLabel: 'X en '+ gps_user_projection.proj.units +' '
                        ,minValue:xmin
                        ,minText:'Cette coordonnée en x n\'est pas valide pour l\'emprise de la carte. Elle doit être supérieure à '+xmin+'.'
                        ,maxValue:xmax
                        ,maxText:'Cette coordonnée en x n\'est pas valide pour l\'emprise de la carte. Elle doit être inférieure à '+xmax+'.'
                        ,allowBlank:false
                        ,blankText: 'La coordonnée en x est obligatoire. Ce doit être un nombre entre '+xmin+' et '+xmax+'.'
                        ,name: 'longitude'
                        ,width: 150
                    },{
                        id: 'gps-fiche-latitude'
                        ,xtype: 'numberfield'
                        ,allowDecimals :true
                        ,allowNegative: true
                        ,decimalPrecision:6
                        ,decimalSeparator:'.'
                        ,disabled:false
                        ,fieldLabel: 'Y en '+ gps_user_projection.proj.units +' '
                        ,minValue:ymin
                        ,minText:'Cette coordonnée en y n\'est pas valide pour l\'emprise de la carte. Elle doit être supérieure à '+ymin+consigneFuseau+'.'
                        ,maxValue:ymax
                        ,maxText:'Cette coordonnée en y n\'est pas valide pour l\'emprise de la carte. Elle doit être inférieure à '+ymax+consigneFuseau+'.'
                        ,allowBlank:false
                        ,blankText: 'La coordonnée en y est obligatoire. Ce doit être un nombre entre '+ymin+' et '+ymax+'.'
                        ,name: 'latitude'
                        ,width: 150
                    }
                    ]
                    ,listeners: {
                        clientvalidation:function(form,valid){
                            if(valid){Ext.getCmp('gps-afficher-button').enable();}
                            else{Ext.getCmp('gps-afficher-button').disable();}
                        }
                    }
                },{
                    id:'panel-export-evenement'
                    ,xtype: 'panel'
                    ,region: 'south'
                    ,frame:true
                    ,border:false
                    ,split: false
                    ,autoScroll:false
                    ,bodyStyle:'padding:5px 5px 0'
                    ,width: 350
                    ,html: msgInfo
                }]
                ,listeners: {
                    hide:function(){this.destroy();}
                } 
            });
        }
    }
}();