import os

from flask import Flask
from flask_user import login_required, UserManager, UserMixin, SQLAlchemyAdapter

#locla imports
from modreg.config import Config
from modreg.extensions import db, login_manager
from modreg.models import WebUsers, WebAdmins

@login_manager.user_loader
def user_loader(user_account):
    return WebUsers.query.get(user_account)

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(Config)

    #pass our app to imported packages
    db.init_app(app)
    user_manager = UserManager(app, db, WebUsers)

    from modreg.main.routes import main
    from modreg.studentUsers.routes import studentUsers

    app.register_blueprint(main)
    app.register_blueprint(studentUsers)

    return app

