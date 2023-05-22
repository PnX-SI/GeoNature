import uuid


def is_valid_uuid(value):
    """
    test si un uuid est valide
    """
    try:
        uuid.UUID(str(value))

        return True
    except ValueError:
        return False
