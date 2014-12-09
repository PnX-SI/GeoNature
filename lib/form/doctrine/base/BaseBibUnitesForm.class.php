<?php

/**
 * BibUnites form base class.
 *
 * @method BibUnites getObject() Returns the current form's model object
 *
 * @package    pa_back
 * @subpackage form
 * @author     Your name here
 * @version    SVN: $Id: sfDoctrineFormGeneratedTemplate.php 29553 2010-05-20 14:33:00Z Kris.Wallsmith $
 */
abstract class BaseBibUnitesForm extends BaseFormDoctrine
{
  public function setup()
  {
    $this->setWidgets(array(
      'id_unite'      => new sfWidgetFormInputHidden(),
      'nom_unite'     => new sfWidgetFormInputText(),
      'adresse_unite' => new sfWidgetFormInputText(),
      'cp_unite'      => new sfWidgetFormInputText(),
      'ville_unite'   => new sfWidgetFormInputText(),
      'tel_unite'     => new sfWidgetFormInputText(),
      'fax_unite'     => new sfWidgetFormInputText(),
      'email_unite'   => new sfWidgetFormInputText(),
    ));

    $this->setValidators(array(
      'id_unite'      => new sfValidatorChoice(array('choices' => array($this->getObject()->get('id_unite')), 'empty_value' => $this->getObject()->get('id_unite'), 'required' => false)),
      'nom_unite'     => new sfValidatorString(array('max_length' => 50, 'required' => false)),
      'adresse_unite' => new sfValidatorString(array('max_length' => 128, 'required' => false)),
      'cp_unite'      => new sfValidatorString(array('max_length' => 5, 'required' => false)),
      'ville_unite'   => new sfValidatorString(array('max_length' => 5, 'required' => false)),
      'tel_unite'     => new sfValidatorString(array('max_length' => 14, 'required' => false)),
      'fax_unite'     => new sfValidatorString(array('max_length' => 14, 'required' => false)),
      'email_unite'   => new sfValidatorString(array('max_length' => 100, 'required' => false)),
    ));

    $this->widgetSchema->setNameFormat('bib_unites[%s]');

    $this->errorSchema = new sfValidatorErrorSchema($this->validatorSchema);

    $this->setupInheritance();

    parent::setup();
  }

  public function getModelName()
  {
    return 'BibUnites';
  }

}
