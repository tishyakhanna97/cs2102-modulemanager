#this file imports extensions and initialize for __init__.py
from flask_sqlalchemy import SQLAlchemy
from flask_bootstrap import Bootstrap
from flask_admin import Admin
from flask_admin.contrib.sqla import ModelView
from flask_login import LoginManager,login_user, UserMixin

#initialize db, SQLAlchemy is a convenient python extension to help manage database
db = SQLAlchemy()

#initialize login manager
login_manager = LoginManager()