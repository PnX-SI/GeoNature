<?php

/**
 * TPrecisions form base class.
 *
 * @method TPrecisions getObject() Returns the current form's model object
 *
 * @package    pa_back
 * @subpackage form
 * @author     Your name here
 * @version    SVN: $Id: sfDoctrineFormGeneratedTemplate.php 29553 2010-05-20 14:33:00Z Kris.Wallsmith $
 */
abstract class BaseTPrecisionsForm extends BaseFormDoctrine
{
  public function setup()
  {
    $this->setWidgets(array(
      'id_precision'   => new sfWidgetFormInputHidden(),
      'nom_precision'  => new sfWidgetFormInputText(),
      'desc_precision' => new sfWidgetFormTextarea(),
    ));

    $this->setValidators(array(
      'id_precision'   => new sfValidatorChoice(array('choices' => array($this->getObject()->get('id_precision')), 'empty_value' => $this->getObject()->get('id_precision'), 'required' => false)),
      'nom_precision'  => new sfValidatorString(array('max_length' => 50, 'required' => false)),
      'desc_precision' => new sfValidatorString(array('required' => false)),
    ));

    $this->widgetSchema->setNameFormat('t_precisions[%s]');

    $this->errorSchema = new sfValidatorErrorSchema($this->validatorSchema);

    $this->setupInheritance();

    parent::setup();
  }

  public function getModelName()
  {
    return 'TPrecisions';
  }

}
