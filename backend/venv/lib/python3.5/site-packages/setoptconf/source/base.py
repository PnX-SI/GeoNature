
__all__ = (
    'Source',
)


class Source(object):
    def get_config(self, settings, manager=None, parent=None):
        raise NotImplementedError()
