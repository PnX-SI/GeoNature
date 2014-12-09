<?php

/**
 * BibTaxrefStatuts form base class.
 *
 * @method BibTaxrefStatuts getObject() Returns the current form's model object
 *
 * @package    pa_back
 * @subpackage form
 * @author     Your name here
 * @version    SVN: $Id: sfDoctrineFormGeneratedTemplate.php 29553 2010-05-20 14:33:00Z Kris.Wallsmith $
 */
abstract class BaseBibTaxrefStatutsForm extends BaseFormDoctrine
{
  public function setup()
  {
    $this->setWidgets(array(
      'id_statut'  => new sfWidgetFormInputHidden(),
      'nom_statut' => new sfWidgetFormInputText(),
    ));

    $this->setValidators(array(
      'id_statut'  => new sfValidatorChoice(array('choices' => array($this->getObject()->get('id_statut')), 'empty_value' => $this->getObject()->get('id_statut'), 'required' => false)),
      'nom_statut' => new sfValidatorString(array('max_length' => 50, 'required' => false)),
    ));

    $this->widgetSchema->setNameFormat('bib_taxref_statuts[%s]');

    $this->errorSchema = new sfValidatorErrorSchema($this->validatorSchema);

    $this->setupInheritance();

    parent::setup();
  }

  public function getModelName()
  {
    return 'BibTaxrefStatuts';
  }

}
