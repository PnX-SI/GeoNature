<?php

/**
 * CorFicheTaxon form base class.
 *
 * @method CorFicheTaxon getObject() Returns the current form's model object
 *
 * @package    pa_back
 * @subpackage form
 * @author     Your name here
 * @version    SVN: $Id: sfDoctrineFormGeneratedTemplate.php 29553 2010-05-20 14:33:00Z Kris.Wallsmith $
 */
abstract class BaseCorFicheTaxonForm extends BaseFormDoctrine
{
  public function setup()
  {
    $this->setWidgets(array(
      'id_taxon' => new sfWidgetFormInputHidden(),
      'id_fiche' => new sfWidgetFormDoctrineChoice(array('model' => $this->getRelatedModelName('TFichesCigales'), 'add_empty' => false)),
    ));

    $this->setValidators(array(
      'id_taxon' => new sfValidatorChoice(array('choices' => array($this->getObject()->get('id_taxon')), 'empty_value' => $this->getObject()->get('id_taxon'), 'required' => false)),
      'id_fiche' => new sfValidatorDoctrineChoice(array('model' => $this->getRelatedModelName('TFichesCigales'))),
    ));

    $this->widgetSchema->setNameFormat('cor_fiche_taxon[%s]');

    $this->errorSchema = new sfValidatorErrorSchema($this->validatorSchema);

    $this->setupInheritance();

    parent::setup();
  }

  public function getModelName()
  {
    return 'CorFicheTaxon';
  }

}
