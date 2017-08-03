from pylint_common.augmentations import apply_augmentations


def register(linter):
    apply_augmentations(linter)
