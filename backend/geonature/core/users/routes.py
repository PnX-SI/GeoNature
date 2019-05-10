import requests

from flask import Blueprint, request, current_app, Response, jsonify, redirect

from geonature.utils.env import DB
from geonature.core.users.models import VUserslistForallMenu, BibOrganismes, CorRole
from pypnusershub.db.models import User
from pypnusershub.db.models_register import TempUser
from pypnusershub.routes_register import bp as user_api

from geonature.utils.utilssqlalchemy import json_resp
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_meta.models import CorDatasetActor, TDatasets
from geonature.core.gn_meta.repositories import get_datasets_cruved


routes = Blueprint("users", __name__)
s = requests.Session()
config = current_app.config


@routes.route("/menu/<int:id_menu>", methods=["GET"])
@json_resp
def getRolesByMenuId(id_menu):
    """
        Retourne la liste des roles associés à un menu

        Parameters
        ----------
         - nom_complet : début du nom complet du role
    """
    q = DB.session.query(VUserslistForallMenu).filter_by(id_menu=id_menu)

    parameters = request.args
    if parameters.get("nom_complet"):
        q = q.filter(
            VUserslistForallMenu.nom_complet.ilike(
                "{}%".format(parameters.get("nom_complet"))
            )
        )
    data = q.order_by(VUserslistForallMenu.nom_complet.asc()).all()
    return [n.as_dict() for n in data]


@routes.route("/role/<int:id_role>", methods=["GET"])
@json_resp
def get_role(id_role):
    """
        Retourne le détail d'un role
    """
    user = DB.session.query(User).filter_by(id_role=id_role).one()
    return user.as_dict()


@routes.route("/role", methods=["POST"])
@json_resp
def insert_role(user=None):
    """
        Insert un role
        @TODO : Ne devrait pas être là mais dans UserHub
        Utilisé dans l'authentification du CAS INPN
    """
    if user:
        data = user
    else:
        data = dict(request.get_json())
    user = User(**data)
    if user.id_role is not None:
        exist_user = DB.session.query(User).get(user.id_role)
        if exist_user:
            DB.session.merge(user)
        else:
            DB.session.add(user)
    else:
        DB.session.add(user)
    DB.session.commit()
    DB.session.flush()
    return user.as_dict()


@routes.route("/inscription", methods=["POST"])
def inscription():
    """
        Inscrit un user à partir de l'interface geonature
        Fonctionne selon l'autorisation 'ENABLE_SIGN_UP' dans la config.
        Fait appel à l'API UsersHub
    """
    #test des droits
    if (not config.get('ENABLE_SIGN_UP', False)):
        return jsonify({"message": "Page introuvable"}), 404

    data = request.get_json()
    #ajout des valeurs non présentes dans le form
    data['groupe'] = False
    data['url_confirmation'] = config['API_ENDPOINT'] + "/users/confirmation"

    r = s.post(url=config['API_ENDPOINT'] + "/pypn/register/post_usershub/create_temp_user", json=data)

    return Response(r), r.status_code


@routes.route("/confirmation", methods=["GET"])
def confirmation():
    """
        Confirmation du mail
        Fait appel à l'API UsersHub
    """
    #test des droits
    if (not config.get('ENABLE_SIGN_UP', False)):
        return jsonify({"message": "Page introuvable"}), 404

    token = request.args.get('token', None)
    if token is None:
        return jsonify({"message": "Token introuvable"}), 404

    data = {"token": token, "id_application": config['ID_APPLICATION_GEONATURE']}

    r = s.post(url=config['API_ENDPOINT'] + "/pypn/register/post_usershub/valid_temp_user", json=data)
    if r.status_code != 200:
        return Response(r), r.status_code

    return redirect(config['URL_APPLICATION'], code=302)


@routes.route("/role", methods=["PUT"])
@permissions.check_cruved_scope("R", True)
@json_resp
def update_role(info_role):
    """
        Modifie le role de l'utilisateur du token en cours
    """
    data = dict(request.get_json())

    user = DB.session.query(User).get(info_role.id_role)

    if user is None:
        return {"message": "Droit insuffisant"}, 403

    attliste = [k for k in data]
    for att in attliste:
        if not getattr(User, att, False):
            data.pop(att)

    #liste des attributs qui ne doivent pas être modifiable par l'user
    black_list_att_update = [
        'active', 
        'date_insert', 
        'date_update', 
        'groupe', 
        'id_organisme', 
        'id_role', 
        'pass_plus', 
        'pn', 
        'uuid_role'
    ]
    for key, value in data.items():
        if key not in black_list_att_update:
            setattr(user, key, value)

    DB.session.merge(user)
    DB.session.commit()
    DB.session.flush()
    return user.as_dict()


@routes.route("/password", methods=["PUT"])
@permissions.check_cruved_scope("R", True)
def update_password(info_role):
    """
        Modifie le role de l'utilisateur du token en cours
        Fait appel à l'API UsersHub
    """
    data = request.get_json()
    user = DB.session.query(User).get(info_role.id_role)
    
    if user is None:
        return jsonify({"msg": "Droit insuffisant"}), 403

    #Vérification du password initiale du role
    if not user.check_password(data.get('init_password', None)):
        return jsonify({"msg": "Le mot de passe initial est invalide"}), 400

    #recuperation du token usershub API
    token = s.post(url=config['API_ENDPOINT'] + "/pypn/register/post_usershub/create_cor_role_token", json={'email': user.email}).json()

    data['token'] = token['token']
    r = s.post(url=config['API_ENDPOINT'] + "/pypn/register/post_usershub/change_password", json=data)

    if r.status_code != 200:
        #comme concerne le password, on explicite pas le message
        return jsonify({"msg": "Erreur serveur"}), 500

    return jsonify({"msg": "Mot de passe modifié avec succès"}), 200
    

@routes.route("/cor_role", methods=["POST"])
@json_resp
def insert_in_cor_role(id_group=None, id_user=None):
    """
        Insert une correspondante role groupe
        c-a-d permet d'attacher un role à un groupe
       # TODO ajouter test sur les POST de données
    """
    exist_user = (
        DB.session.query(CorRole)
        .filter(CorRole.id_role_groupe == id_group)
        .filter(CorRole.id_role_utilisateur == id_user)
        .all()
    )
    if not exist_user:
        cor_role = CorRole(id_group, id_user)
        DB.session.add(cor_role)
        DB.session.commit()
        DB.session.flush()
        return cor_role.as_dict()
    return {"message": "cor already exists"}, 500


@routes.route("/organism", methods=["POST"])
@json_resp
def insert_organism(organism):
    """
        Insert un organisme
    """
    if organism is not None:
        data = organism
    else:
        data = dict(request.get_json())
    organism = BibOrganismes(**data)
    if organism.id_organisme:
        exist_org = DB.session.query(BibOrganismes).get(organism.id_organisme)
        if exist_org:
            DB.session.merge(organism)
        else:
            DB.session.add(organism)
    else:
        DB.session.add(organism)
    DB.session.commit()
    DB.session.flush()
    return organism.as_dict()


@routes.route("/roles", methods=["GET"])
@json_resp
def get_roles():
    """
        Retourne tous les roles
    """
    params = request.args
    q = DB.session.query(User)
    if "group" in params:
        q = q.filter(User.groupe == params["group"])
    return [user.as_dict() for user in q.all()]


@routes.route("/organisms", methods=["GET"])
@json_resp
def get_organismes():
    """
        Retourne tous les organismes
    """
    organisms = DB.session.query(BibOrganismes).all()
    return [organism.as_dict() for organism in organisms]


@routes.route("/organisms_dataset_actor", methods=["GET"])
@permissions.check_cruved_scope("R", True)
@json_resp
def get_organismes_jdd(info_role):
    """
        Retourne tous les organismes qui sont acteurs dans un JDD
        et dont l'utilisateur a des droit sur ce JDD (via son CRUVED)
    """

    datasets = [dataset["id_dataset"] for dataset in get_datasets_cruved(info_role)]
    organisms = (
        DB.session.query(BibOrganismes)
        .join(
            CorDatasetActor, BibOrganismes.id_organisme == CorDatasetActor.id_organism
        )
        .filter(CorDatasetActor.id_dataset.in_(datasets))
        .distinct(BibOrganismes.id_organisme)
        .all()
    )
    return [organism.as_dict() for organism in organisms]
