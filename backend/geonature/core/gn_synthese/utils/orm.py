from contextlib import suppress
from sqlalchemy.sql import visitors


def is_already_joined(my_class, query):
    """
    Check if the given class is already present is the current query
    _class: SQLAlchemy class
    query: SQLAlchemy query
    return boolean
    """
    for visitor in visitors.iterate(query.statement):
        # Checking for `.join(Parent.child)` clauses
        if visitor.__visit_name__ == "binary":
            for vis in visitors.iterate(visitor):
                # Visitor might not have table attribute
                with suppress(AttributeError):
                    # Verify if already present based on table name
                    if my_class.__table__.fullname == vis.table.fullname:
                        return True
        # Checking for `.join(Child)` clauses
        if visitor.__visit_name__ == "table":
            # Visitor might be of ColumnCollection or so,
            # which cannot be compared to model
            with suppress(TypeError):
                if my_class == visitor.entity_namespace:
                    return True
        # Checking for `Model.column` clauses
        if visitor.__visit_name__ == "column":
            with suppress(AttributeError):
                if my_class.__table__.fullname == visitor.table.fullname:
                    return True
    return False
