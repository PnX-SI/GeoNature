<body>
<div id="home">
    
    <div class="jumbotron">
        <div id="bandeau_accueil"></div>
        <h1 id="home_title" ><small class="text-muted"><?php echo sfGeonatureConfig::$apptitle_main; ?></small></h1>
    </div>
    <div id="accueil" class="container">

        <h2>SYNTHÈSE</h2>
            <p>Pour consulter la synthèse des observations faune et flore, tous protocoles confondus.</p>
            <p class="ligne_lien">
                 <a href="synthese" class="btn btn-default"><img src="images/pictos/oiseau.gif">Synthèse des observations</a>
            </p>
            <div id="interligne50"></div>
            
        <h2>PROTOCOLES</h2>
            <p>
                Pour saisir de nouvelles données, vous pouvez utiliser l'un des liens ci-dessous.<br/>
                Pour modifier des données saisies à l'aide d'un des formulaires proposés en lien ci-dessous, vous devez passer par la synthèse pour retrouver les enregistrements à modifier.
            </p>
            <p>
                <?php echo $liens_saisie;?>
            </p>
        <?php if(sfGeonatureConfig::$show_statistiques){ ?>
        <h2>STATISTIQUES</h2>
            <div class="row" style="border:1px solid #ddd;">
                <h3>Taxonomie</h3>
                <div class="col-xs-12 col-sm-6 col-md-6 col-lg-4 col-lg-offset-1 text-center">
                    <h3 class="text-primary text-center">Règnes</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="kd-chart" style="height: 250px;" ></div>
                </div>
                <div class="col-xs-12 col-sm-6 col-md-6 col-lg-4 col-lg-offset-1 text-center">
                    <h3 class="text-primary text-center">Classes</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="cl-chart" style="height: 250px;" ></div>
                </div>
                <div class="col-xs-12 col-sm-6 col-md-6 col-lg-4 col-lg-offset-1 text-center">
                    <h3 class="text-primary text-center">Groupe 1 INPN</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="gp1-chart" style="height: 250px;" ></div>
                </div>
                <div class="col-xs-12 col-sm-6 col-md-6 col-lg-4 col-lg-offset-1 text-center">
                    <h3 class="text-primary text-center">Groupe 2 INPN</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="gp2-chart" style="height: 250px;" ></div>
                </div>
            </div>
            <div class="row" style="border:1px solid #ddd;">
                <h3>Autre</h3>
                <div class="text-center">
                    <h3 class="text-primary text-center">Années</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="year-chart" style="height: 250px;" ></div>
                </div>
                <div class="text-center">
                    <h3 class="text-primary text-center">Organismes producteurs</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="org-chart" style="height: 250px;" ></div>
                </div>
            </div>
            <div class="row" style="border:1px solid #ddd;">
                <h3>Programmes de la synthèse</h3>
                <div class="text-center">
                    <h3 class="text-primary text-center">Programmes</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="prog-chart-obs" style="height: 250px;" ></div>
                </div>
                <div class="text-center">
                    <h3 class="text-primary text-center">Programmes</h3>
                    <label class="label label-success">Nombre de taxons</label>
                    <div id="prog-chart-tx" style="height: 250px;" ></div>
                </div>
            </div>
            <div class="row" style="border:1px solid #ddd;">
                <h3>Protocoles GeoNature</h3>
                <?php  if (in_array(sfGeonatureConfig::$id_source_cf, $actives_sources)) { ?>
                <div class="col-xs-12 col-sm-6 col-md-6 col-lg-4 col-lg-offset-1 text-center">
                    <h3 class="text-primary text-center">Contact faune vertébrée</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="cf-chart" style="height: 250px;" ></div>
                </div>
                <?php }?>
                <?php  if (in_array(sfGeonatureConfig::$id_source_mortalite, $actives_sources)) { ?>
                <div class="col-xs-12 col-sm-6 col-md-6 col-lg-4 col-lg-offset-1 text-center">
                    <h3 class="text-primary text-center">Mortalité</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="mortalite-chart" style="height: 250px;" ></div>
                </div>
                <?php }?>
                <?php  if (in_array(sfGeonatureConfig::$id_source_inv, $actives_sources)) { ?>
                <div class="col-xs-12 col-sm-6 col-md-6 col-lg-4 col-lg-offset-1 text-center">
                    <h3 class="text-primary text-center">Contact faune invertébrée</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="inv-chart" style="height: 250px;" ></div>
                </div>
                <?php }?>
                <?php  if (in_array(sfGeonatureConfig::$id_source_cflore, $actives_sources)) { ?>
                <div class="col-xs-12 col-sm-6 col-md-6 col-lg-4 col-lg-offset-1 text-center">
                    <h3 class="text-primary text-center">Contact flore</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="cflore-chart" style="height: 250px;" ></div>
                </div>
                <?php }?>
                <?php  if (in_array(sfGeonatureConfig::$id_source_florestation, $actives_sources)) { ?>
                <div class="col-xs-12 col-sm-6 col-md-6 col-lg-4 col-lg-offset-1 text-center">
                    <h3 class="text-primary text-center">Flore station</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="fs-chart" style="height: 250px;" ></div>
                </div>
                <?php }?>
                <?php  if (in_array(sfGeonatureConfig::$id_source_florepatri, $actives_sources)) { ?>
                <div class="col-xs-12 col-sm-6 col-md-6 col-lg-4 col-lg-offset-1 text-center">
                    <h3 class="text-primary text-center">Flore prioritaire</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="fp-chart" style="height: 250px;" ></div>
                </div>
                <?php }?>
            </div>
        <?php } ?>
        <footer>
            <h5>
            <small>
                <a href="https://github.com/PnEcrins/GeoNature/" target="_blank">GeoNature</a>
                , développé par le 
                <a href="http://www.ecrins-parcnational.fr" target="_blank">
                Parc national des Ecrins </a>
                - Basé sur Taxref <?php echo sfGeonatureConfig::$taxref_version; ?>
            </small>
            <a class="pull-right" href="deconnexion"><img src="images/logout.gif" title="Déconnexion"/></a>
            </h5>
        </footer>
        
    </div>
</div>
<script>

var constructDatas = function(arr) {
    var datas = [];
    var item;
    for(var i=0; i<arr.length ; i++){
        if(arr[i][0] !=null){
            item = {value: arr[i][1], label: arr[i][0]};
            datas.push(item);
        }
    }
    return datas;
};
var constructDonuts = function(datas,div) {
    return new Morris.Donut({
        element: div
        ,data: datas
        ,backgroundColor: '#ccc'
        ,labelColor: '#666699'
        ,colors:['#f2e5ff','#e5ccff','#d9b3ff','#cc99ff','#bf80ff','#bf80ff','#b266ff','#a64dff','#9933ff','#8c1aff','#7f00ff','#7300e6','#6600cc','#5900b3','#4c0099','#400080','#330066','#26004d','#190033','#0d001a']
        ,formatter: function (x) { return x }
    });
};

var constructBars = function(datas,div,labels) {
    return new Morris.Bar({
    element: div,
    data:datas,
    xkey: 'subject',
    ykeys: ['nb'],
    labels: labels,
    barRatio: 0.4,
    xLabelAngle: 25,
    hideHover: 'auto',
    resize:true
  });
};

// var constructLinesWNT = function(datas,div) {
    // return new Morris.Line({
        // element: div,
        // data: datas,
        // xkey: 'd',
        // ykeys: ['web', 'nomade','total'],
        // labels: ['web', 'nomade','total'],
        // hideHover: 'auto'
    // })
// };
var constructSimpleLine = function(datas,div) {
    return new Morris.Line({
        element: div,
        data: datas,
        xkey: 'd',
        ykeys: ['annee','somme'],
        labels: ['annee','total'],
        hideHover: 'auto'
    })
};
function onDataReceived1(series) {
    var datas = constructDatas(series);
    constructDonuts(datas,'kd-chart');  
};
function onDataReceived2(series) {
    var datas = constructDatas(series);
    constructDonuts(datas,'cl-chart');   
};
function onDataReceived3(series) {
    var datas = constructDatas(series);
    constructDonuts(datas,'gp1-chart');  
};
function onDataReceived4(series) {
    var datas = constructDatas(series);
    constructDonuts(datas,'gp2-chart');  
}; 
 
function onDataReceived5(series) {
    constructBars(series,'year-chart',['nombre d\'observations']);   
};
function onDataReceived6(series) {
    constructBars(series,'org-chart',['nombre d\'observations']);   
};

function onDataReceived7(series) {
    constructBars(series,'prog-chart-obs',['nombre d\'observations']);   
};
function onDataReceived8(series) {
    constructBars(series,'prog-chart-tx',['nombre de taxons']);   
};

function onDataReceived9(series) {
    constructSimpleLine(series,'cf-chart');   
};
function onDataReceived10(series) {
    constructSimpleLine(series,'mortalite-chart');   
};
function onDataReceived11(series) {
    constructSimpleLine(series,'inv-chart');   
};
function onDataReceived12(series) {
    constructSimpleLine(series,'cflore-chart');   
};
function onDataReceived13(series) {
    constructSimpleLine(series,'fs-chart');   
};
function onDataReceived14(series) {
    constructSimpleLine(series,'fp-chart');   
};
//récupération des données avec une requête ajax et lancement de la construction du graphique sur le success
function getDatas(url, successFunction) {
    $.ajax({
        url: url
        ,type: "GET"
        ,dataType: "json"
        ,success: successFunction
    });
};
getDatas('datasnbobskd',onDataReceived1);
getDatas('datasnbobscl',onDataReceived2);
getDatas('datasnbobsgp1',onDataReceived3);
getDatas('datasnbobsgp2',onDataReceived4);

getDatas('datasnbobsyear',onDataReceived5);
getDatas('datasnbobsorganisme',onDataReceived6);

getDatas('datasnbobsprogramme',onDataReceived7);
getDatas('datasnbtxprogramme',onDataReceived8);

<?php  if (in_array(sfGeonatureConfig::$id_source_cf, $actives_sources)) { ?>getDatas('datasnbobscf',onDataReceived9);<?php } ?>
<?php  if (in_array(sfGeonatureConfig::$id_source_mortalite, $actives_sources)) { ?>getDatas('datasnbobsmortalite',onDataReceived10);<?php } ?>
<?php  if (in_array(sfGeonatureConfig::$id_source_inv, $actives_sources)) { ?>getDatas('datasnbobsinv',onDataReceived11);<?php } ?>
<?php  if (in_array(sfGeonatureConfig::$id_source_cflore, $actives_sources)) { ?>getDatas('datasnbobscflore',onDataReceived12);<?php } ?>
<?php  if (in_array(sfGeonatureConfig::$id_source_florestation, $actives_sources)) { ?>getDatas('datasnbobsfs',onDataReceived13);<?php } ?>
<?php  if (in_array(sfGeonatureConfig::$id_source_florepatri, $actives_sources)) { ?>getDatas('datasnbobsfp',onDataReceived14);<?php } ?>

</script>
 </body>
