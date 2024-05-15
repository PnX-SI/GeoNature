def metaclass_resolver(*classes):
    metaclass = tuple(set(type(cls) for cls in classes))
    metaclass = (
        metaclass[0]
        if len(metaclass) == 1
        else type("_".join(mcls.__name__ for mcls in metaclass), metaclass, {})
    )  # class M_C
    return metaclass("_".join(cls.__name__ for cls in classes), classes, {})
