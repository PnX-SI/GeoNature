from .core.users.models import UserRigth


admin_read = UserRigth(
  id_role = 1,
  id_organism = 2,
  tag_action_code = 'R',
  tag_object_code = '3',
  id_application = 14
  )

agent_read = UserRigth(
  id_role = 2,
  id_organism = -1,
  tag_action_code = 'R',
  tag_object_code = '2',
  id_application = 14
  )

partenaire_read = UserRigth(
  id_role = 3,
  id_organism = -1,
  tag_action_code = 'R',
  tag_object_code = '1',
  id_application = 14
  )