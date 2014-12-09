<?php

/**
 * TFichesCigales form base class.
 *
 * @method TFichesCigales getObject() Returns the current form's model object
 *
 * @package    pa_back
 * @subpackage form
 * @author     Your name here
 * @version    SVN: $Id: sfDoctrineFormGeneratedTemplate.php 29553 2010-05-20 14:33:00Z Kris.Wallsmith $
 */
abstract class BaseTFichesCigalesForm extends BaseFormDoctrine
{
  public function setup()
  {
    $this->setWidgets(array(
      'id_fiche'     => new sfWidgetFormInputHidden(),
      'id_role'      => new sfWidgetFormInputText(),
      'id_transect'  => new sfWidgetFormInputText(),
      'id_protocole' => new sfWidgetFormInputText(),
      'date_obs'     => new sfWidgetFormDate(),
      'sens'         => new sfWidgetFormInputText(),
      'heure_debut'  => new sfWidgetFormDateTime(),
      'date_insert'  => new sfWidgetFormDateTime(),
      'date_update'  => new sfWidgetFormDateTime(),
    ));

    $this->setValidators(array(
      'id_fiche'     => new sfValidatorChoice(array('choices' => array($this->getObject()->get('id_fiche')), 'empty_value' => $this->getObject()->get('id_fiche'), 'required' => false)),
      'id_role'      => new sfValidatorInteger(array('required' => false)),
      'id_transect'  => new sfValidatorInteger(array('required' => false)),
      'id_protocole' => new sfValidatorInteger(array('required' => false)),
      'date_obs'     => new sfValidatorDate(),
      'sens'         => new sfValidatorString(array('max_length' => 1, 'required' => false)),
      'heure_debut'  => new sfValidatorDateTime(array('required' => false)),
      'date_insert'  => new sfValidatorDateTime(array('required' => false)),
      'date_update'  => new sfValidatorDateTime(array('required' => false)),
    ));

    $this->widgetSchema->setNameFormat('t_fiches_cigales[%s]');

    $this->errorSchema = new sfValidatorErrorSchema($this->validatorSchema);

    $this->setupInheritance();

    parent::setup();
  }

  public function getModelName()
  {
    return 'TFichesCigales';
  }

}
