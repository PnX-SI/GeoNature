<?php

/**
 * BibTaxrefRangs form base class.
 *
 * @method BibTaxrefRangs getObject() Returns the current form's model object
 *
 * @package    pa_back
 * @subpackage form
 * @author     Your name here
 * @version    SVN: $Id: sfDoctrineFormGeneratedTemplate.php 29553 2010-05-20 14:33:00Z Kris.Wallsmith $
 */
abstract class BaseBibTaxrefRangsForm extends BaseFormDoctrine
{
  public function setup()
  {
    $this->setWidgets(array(
      'id_rang'  => new sfWidgetFormInputHidden(),
      'nom_rang' => new sfWidgetFormInputText(),
    ));

    $this->setValidators(array(
      'id_rang'  => new sfValidatorChoice(array('choices' => array($this->getObject()->get('id_rang')), 'empty_value' => $this->getObject()->get('id_rang'), 'required' => false)),
      'nom_rang' => new sfValidatorString(array('max_length' => 20, 'required' => false)),
    ));

    $this->widgetSchema->setNameFormat('bib_taxref_rangs[%s]');

    $this->errorSchema = new sfValidatorErrorSchema($this->validatorSchema);

    $this->setupInheritance();

    parent::setup();
  }

  public function getModelName()
  {
    return 'BibTaxrefRangs';
  }

}
