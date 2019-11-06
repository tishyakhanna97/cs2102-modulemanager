import os

from flask import Flask
from flask_user import login_required, UserManager, UserMixin, SQLAlchemyAdapter

#locla imports
from modreg.config import Config
from modreg.extensions import db, login_manager
from modreg.models import WebUser, WebAdmins   

@login_manager.user_loader
def user_loader(user_account):
    return WebUser.query.get(user_account)

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(Config)

    #pass our app to imported packages
    db.init_app(app)
    user_manager = UserManager(app, db, WebUser)

    from modreg.main.routes import main
    from modreg.students.routes import students

    app.register_blueprint(main)
    app.register_blueprint(students)

    return app

