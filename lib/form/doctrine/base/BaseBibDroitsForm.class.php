<?php

/**
 * BibDroits form base class.
 *
 * @method BibDroits getObject() Returns the current form's model object
 *
 * @package    pa_back
 * @subpackage form
 * @author     Your name here
 * @version    SVN: $Id: sfDoctrineFormGeneratedTemplate.php 29553 2010-05-20 14:33:00Z Kris.Wallsmith $
 */
abstract class BaseBibDroitsForm extends BaseFormDoctrine
{
  public function setup()
  {
    $this->setWidgets(array(
      'id_droit'   => new sfWidgetFormInputHidden(),
      'nom_droit'  => new sfWidgetFormInputText(),
      'desc_droit' => new sfWidgetFormTextarea(),
    ));

    $this->setValidators(array(
      'id_droit'   => new sfValidatorChoice(array('choices' => array($this->getObject()->get('id_droit')), 'empty_value' => $this->getObject()->get('id_droit'), 'required' => false)),
      'nom_droit'  => new sfValidatorString(array('max_length' => 50, 'required' => false)),
      'desc_droit' => new sfValidatorString(array('required' => false)),
    ));

    $this->widgetSchema->setNameFormat('bib_droits[%s]');

    $this->errorSchema = new sfValidatorErrorSchema($this->validatorSchema);

    $this->setupInheritance();

    parent::setup();
  }

  public function getModelName()
  {
    return 'BibDroits';
  }

}
