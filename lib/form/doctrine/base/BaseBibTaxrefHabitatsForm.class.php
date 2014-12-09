<?php

/**
 * BibTaxrefHabitats form base class.
 *
 * @method BibTaxrefHabitats getObject() Returns the current form's model object
 *
 * @package    pa_back
 * @subpackage form
 * @author     Your name here
 * @version    SVN: $Id: sfDoctrineFormGeneratedTemplate.php 29553 2010-05-20 14:33:00Z Kris.Wallsmith $
 */
abstract class BaseBibTaxrefHabitatsForm extends BaseFormDoctrine
{
  public function setup()
  {
    $this->setWidgets(array(
      'id_habitat'  => new sfWidgetFormInputHidden(),
      'nom_habitat' => new sfWidgetFormInputText(),
    ));

    $this->setValidators(array(
      'id_habitat'  => new sfValidatorChoice(array('choices' => array($this->getObject()->get('id_habitat')), 'empty_value' => $this->getObject()->get('id_habitat'), 'required' => false)),
      'nom_habitat' => new sfValidatorString(array('max_length' => 50, 'required' => false)),
    ));

    $this->widgetSchema->setNameFormat('bib_taxref_habitats[%s]');

    $this->errorSchema = new sfValidatorErrorSchema($this->validatorSchema);

    $this->setupInheritance();

    parent::setup();
  }

  public function getModelName()
  {
    return 'BibTaxrefHabitats';
  }

}
