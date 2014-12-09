<?php

/**
 * TRelevesCigales form base class.
 *
 * @method TRelevesCigales getObject() Returns the current form's model object
 *
 * @package    pa_back
 * @subpackage form
 * @author     Your name here
 * @version    SVN: $Id: sfDoctrineFormGeneratedTemplate.php 29553 2010-05-20 14:33:00Z Kris.Wallsmith $
 */
abstract class BaseTRelevesCigalesForm extends BaseFormDoctrine
{
  public function setup()
  {
    $this->setWidgets(array(
      'id_releve'             => new sfWidgetFormInputHidden(),
      'id_role'               => new sfWidgetFormDoctrineChoice(array('model' => $this->getRelatedModelName('TRoles'), 'add_empty' => true)),
      'id_transect'           => new sfWidgetFormDoctrineChoice(array('model' => $this->getRelatedModelName('TTransects'), 'add_empty' => true)),
      'id_protocole'          => new sfWidgetFormInputText(),
      'date_obs'              => new sfWidgetFormDate(),
      'sens'                  => new sfWidgetFormInputText(),
      'heure_debut'           => new sfWidgetFormDateTime(),
      'date_insert'           => new sfWidgetFormDateTime(),
      'date_update'           => new sfWidgetFormDateTime(),
      'supprime'              => new sfWidgetFormInputCheckbox(),
      'verrou'                => new sfWidgetFormInputCheckbox(),
      'ecolocateur'           => new sfWidgetFormInputCheckbox(),
      'id_utilisateur_verrou' => new sfWidgetFormInputText(),
      'date_verrou'           => new sfWidgetFormDateTime(),
    ));

    $this->setValidators(array(
      'id_releve'             => new sfValidatorChoice(array('choices' => array($this->getObject()->get('id_releve')), 'empty_value' => $this->getObject()->get('id_releve'), 'required' => false)),
      'id_role'               => new sfValidatorDoctrineChoice(array('model' => $this->getRelatedModelName('TRoles'), 'required' => false)),
      'id_transect'           => new sfValidatorDoctrineChoice(array('model' => $this->getRelatedModelName('TTransects'), 'required' => false)),
      'id_protocole'          => new sfValidatorInteger(array('required' => false)),
      'date_obs'              => new sfValidatorDate(),
      'sens'                  => new sfValidatorString(array('max_length' => 1, 'required' => false)),
      'heure_debut'           => new sfValidatorDateTime(array('required' => false)),
      'date_insert'           => new sfValidatorDateTime(array('required' => false)),
      'date_update'           => new sfValidatorDateTime(array('required' => false)),
      'supprime'              => new sfValidatorBoolean(array('required' => false)),
      'verrou'                => new sfValidatorBoolean(array('required' => false)),
      'ecolocateur'           => new sfValidatorBoolean(array('required' => false)),
      'id_utilisateur_verrou' => new sfValidatorInteger(array('required' => false)),
      'date_verrou'           => new sfValidatorDateTime(array('required' => false)),
    ));

    $this->widgetSchema->setNameFormat('t_releves_cigales[%s]');

    $this->errorSchema = new sfValidatorErrorSchema($this->validatorSchema);

    $this->setupInheritance();

    parent::setup();
  }

  public function getModelName()
  {
    return 'TRelevesCigales';
  }

}
