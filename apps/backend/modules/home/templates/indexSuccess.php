<body>
<div id="home">
    
    <div class="jumbotron">
        <div id="bandeau_accueil"></div>
        <h1 id="home_title" ><small class="text-muted"><?php echo sfGeonatureConfig::$apptitle_main; ?></small></h1>
    </div>
    <div id ="container">

        <h2>Consultation</h2>
        <p>Pour consulter la synthèse des observations faune et flore, tous protocoles confondus.</p>
        <p class="ligne_lien">
             <a href="synthese" class="btn btn-default"><img src="images/pictos/oiseau.gif">Synthèse des observations</a>
        </p>
        <div id="interligne50"></div>
            
        <h2>Saisie</h2>
        <p>
            Pour saisir de nouvelles données, vous pouvez utiliser l'un des liens ci-dessous.<br/>
            Pour modifier des données saisies à l'aide d'un des formulaires proposés en lien ci-dessous, vous devez passer par la synthèse pour retrouver les enregistrements à modifier.
        </p>
        <p>
            <? echo $liens_saisie;?>
        </p>
            <!-- BLOC DE STATS PNE NON AFFICHES. A REINTEGRER SOUS FORME DE IFRAME CUSTOMISABLE ?
            <div id="bande_consultation" style="color:#FFFFFF;background: linear-gradient(90deg, #f09819 30%, #edde5d 90%) repeat scroll 0 0 rgba(0, 0, 0, 0);letter-spacing:5px;font-weight:bold;text-shadow:0 0 3px #000;height:25px;">
                <div style="vertical-align:middle;display:inline-block;"><img src="images/logo_pag.png" border="0" width="25px" height="25px"></div>
                <div style="vertical-align:middle;display:inline-block;">STATISTIQUES</div>
            </div>
            <div>
                <div id="header">
                    <h2>Utilisation des outils de saisie Faune</h2>
                </div>
                <div id="content">
                    <div id="header">
                        <h3>Cumul des observations selon le mode de saisie</h3>
                    </div>
                    <div class="demo-container">
                        <p>Faune vertébrée</p>
                        <div id="placeholder1" class="demo-placeholder"></div>
                    </div>             
                    <div class="demo-container">
                        <p>Faune invertébrée</p>
                        <div id="placeholder3" class="demo-placeholder"></div>
                    </div>

                    <br/>
                    <div id="header">
                        <h3>Evolution du nombre d'espèces vues ou à rechercher</h3>
                    </div>
                    <div class="demo-container">
                        <p>Faune vertébrée</p>
                        <div id="placeholder2" class="demo-placeholder"></div>
                    </div>
                    
                    <div class="demo-container">
                        <p>Faune invertébrée</p>
                        <div id="placeholder4" class="demo-placeholder"></div>
                    </div>
                </div>
            </div>
            -->

        <footer>
            <h5>
            <small>
                <a href="https://github.com/PnEcrins/GeoNature/" target="_blank">GeoNature</a>
                , développé par le 
                <a href="http://www.ecrins-parcnational.fr" target="_blank">
                Parc national des Ecrins</a>
            </small>
            <a class="pull-right" href="deconnexion"><img src="images/logout.gif" title="Déconnexion"/></a>
            </h5>
        </footer>
    </div>
</div>
 </body>
