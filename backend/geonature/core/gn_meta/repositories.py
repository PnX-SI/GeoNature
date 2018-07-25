from sqlalchemy import or_

from geonature.utils.env import DB

from geonature.core.gn_meta.models import (
    TDatasets,
    CorDatasetActor, TAcquisitionFramework,
    CorAcquisitionFrameworkActor
)


def get_datasets_cruved(info_role):
    """
        Return the datasets filtered with cruved 
    """
    q = DB.session.query(TDatasets)
    if info_role.tag_object_code == '2':
        q = q.join(
            CorDatasetActor,
            CorDatasetActor.id_dataset == TDatasets.id_dataset
        )
        # if organism is None => do not filter on id_organism even if level = 2
        if info_role.id_organisme is None:
            q = q.filter(
                CorDatasetActor.id_role == info_role.id_role
            )
        else:
            q = q.filter(
                or_(
                    CorDatasetActor.id_organism == info_role.id_organisme,
                    CorDatasetActor.id_role == info_role.id_role
                )
            )
    elif info_role.tag_object_code == '1':
        q = q.join(
            CorDatasetActor,
            CorDatasetActor.id_dataset == TDatasets.id_dataset
        ).filter(
            CorDatasetActor.id_role == info_role.id_role
        )
    data = q.all()
    return [d.as_dict(True) for d in data]


def get_af_cruved(info_role):
    """
        Return the datasets filtered with cruved 
    """
    q = DB.session.query(TAcquisitionFramework)
    if info_role.tag_object_code == '2':
        q = q.join(
            CorDatasetActor,
            CorAcquisitionFrameworkActor.id_acquisition_framework == TDatasets.id_acquisition_framework
        )
        # if organism is None => do not filter on id_organism even if level = 2
        if info_role.id_organisme is None:
            q = q.filter(
                CorAcquisitionFrameworkActor.id_role == info_role.id_role
            )
        else:
            q = q.filter(
                or_(
                    CorAcquisitionFrameworkActor.id_organism == info_role.id_organisme,
                    CorAcquisitionFrameworkActor.id_role == info_role.id_role
                )
            )
    elif info_role.tag_object_code == '1':
        q = q.join(
            CorAcquisitionFrameworkActor,
            CorAcquisitionFrameworkActor.id_acquisition_framework == TAcquisitionFramework.id_acquisition_framework
        ).filter(
            CorAcquisitionFrameworkActor.id_role == info_role.id_role
        )
    data = q.all()
    return [d.as_dict(True) for d in data]
