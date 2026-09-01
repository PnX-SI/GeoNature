import click
from pypnusershub.db import User

from geonature.core.command import main


@main.command(help="Verify the status of the installation")
@click.option("--verbose", "-v", is_flag=True, help="Detail the verification steps.")
def status(verbose):
    """
    Performs various checks to verify the status, for this current installation.
    If needed, correction actions are offered to the user

    Current checks :
    - Check if the password for the admin user is set to the default value 'admin' still.
    """

    list_check_functions = [
        verify_admin_password_is_modified,
    ]

    with click.progressbar(
        list_check_functions,
        label="Checking installation status",
        item_show_func=lambda x: "" if x is None else x.label,
    ) as bar:
        for i, check_function in enumerate(bar):

            message_check = verify_admin_password_is_modified(verbose)

            # "Hide" the progressbar before displaying the result of the current check
            print("\r\033[K", end="")
            if message_check is not None:
                print(message_check)


PASSWORD_DEFAULT_ADMIN = "admin"


def verify_admin_password_is_modified(verbose=False):

    admin_user = User.query.filter(User.identifiant == "admin").one_or_none()

    if admin_user is None:
        if verbose:
            return click.style("There is no user named 'admin'.", fg="yellow")
        return

    if admin_user.check_password(PASSWORD_DEFAULT_ADMIN):

        return click.style(
            "⚠ admin user still has default password 'admin'. Strongly consider changing it !",
            fg="red",
        )
    else:

        if verbose:
            return click.style(
                "✓ admin user has not default password 'admin' anymore.", fg="green"
            )


verify_admin_password_is_modified.label = "Checking admin password"
