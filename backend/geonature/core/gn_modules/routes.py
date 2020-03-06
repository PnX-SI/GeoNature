from flask import Blueprint, Flask, render_template

routes = Blueprint("gn_modules", __name__, template_folder="templates")

@routes.route('/<module_code>', methods=['GET'])
def serve_bundle(module_code):
    """
    Route to serve a module bundle
    render a template the GN home page
    """
    module_ng_app = '{}/index.html'.format(module_code)
    return render_template(module_ng_app)

