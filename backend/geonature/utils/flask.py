def safe_get(data, key, default=None, type=None):
    """
    Safely retrieves a value from a dictionary, with optional type-casting and a default fallback.

    If the item is not castable to the desired type, we return default value.

    Parameters
    ----------
    data :
    key :
    default : Any, optional
        The default value to return
    type : callable, optional
        A callable that specifies the type to cast the value to, such as `int`, `str`, etc.

    Returns
    -------
    Any
    """
    value = data.get(key, default)
    if value is None:
        return default
    try:
        return type(value) if type else value
    except (ValueError, TypeError):
        return default
