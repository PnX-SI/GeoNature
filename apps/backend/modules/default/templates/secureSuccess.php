<?php use_helper('Url') ?>  
<div class="container">
    <form class="form-signin" action="<?php echo url_for('@login') ?>" method="post" id="loginForm">
    
        <h2 class="form-signin-heading"><?php echo sfGeonatureConfig::$appname_main;?></h2>
        
          <div class="alert alert-danger fade in">
                <strong>Erreur ! </strong>Vous n'avez pas les droits nécessaires pour accéder à cette page.<br/>
                <a href="<?php echo url_for('@login')?>">Vous devez vous identifier de nouveau</a>
          </div>

    </form>
</div>