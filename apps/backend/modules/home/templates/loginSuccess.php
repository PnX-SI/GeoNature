<?php use_helper('Url') ?>
<div id="container">
    <form class="form-signin" action="<?php echo url_for('@login') ?>" method="post" id="loginForm">
    
        <h2 class="form-signin-heading"><?php echo sfGeonatureConfig::$appname_main;?></h2>
        <?php 
            echo $form['login']->renderLabel(null, array('class' => 'sr-only')); 
            echo $form['login'];
            echo $form['password']->renderLabel(null, array('class' => 'sr-only')); 
            echo $form['password']; 
            if ($form['password']->hasError()){
        ?>
          <div class="alert alert-danger fade in">
                <strong>Erreur ! </strong><?php echo $form['password']->getError(); ?>
          </div>
        <?php } ?>
        <?php if ($form['login']->hasError()){ ?>
          <div class="alert alert-danger fade in">
                <strong>Erreur ! </strong><?php echo $form['login']->getError(); ?>
        <?php } ?>
        <button class="btn btn-lg btn-success btn-block"  id="submit" type="submit" value="Connexion">Connexion</button>
        </div>
    </form>
</div>


