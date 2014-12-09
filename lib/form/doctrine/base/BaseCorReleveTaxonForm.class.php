<?php

/**
 * CorReleveTaxon form base class.
 *
 * @method CorReleveTaxon getObject() Returns the current form's model object
 *
 * @package    pa_back
 * @subpackage form
 * @author     Your name here
 * @version    SVN: $Id: sfDoctrineFormGeneratedTemplate.php 29553 2010-05-20 14:33:00Z Kris.Wallsmith $
 */
abstract class BaseCorReleveTaxonForm extends BaseFormDoctrine
{
  public function setup()
  {
    $this->setWidgets(array(
      'id_taxon'  => new sfWidgetFormInputHidden(),
      'id_releve' => new sfWidgetFormDoctrineChoice(array('model' => $this->getRelatedModelName('TRelevesCigales'), 'add_empty' => false)),
    ));

    $this->setValidators(array(
      'id_taxon'  => new sfValidatorChoice(array('choices' => array($this->getObject()->get('id_taxon')), 'empty_value' => $this->getObject()->get('id_taxon'), 'required' => false)),
      'id_releve' => new sfValidatorDoctrineChoice(array('model' => $this->getRelatedModelName('TRelevesCigales'))),
    ));

    $this->widgetSchema->setNameFormat('cor_releve_taxon[%s]');

    $this->errorSchema = new sfValidatorErrorSchema($this->validatorSchema);

    $this->setupInheritance();

    parent::setup();
  }

  public function getModelName()
  {
    return 'CorReleveTaxon';
  }

}
