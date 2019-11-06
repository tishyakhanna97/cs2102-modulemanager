import sqlalchemy
from flask import current_app
from modreg import db
from datetime import datetime
from flask_user import roles_required, UserMixin


class WebUser(db.Model):
    __tablename__ = 'User'
    __table_args__ = {'extend_existing': True}
    uid = db.Column(db.String(30), primary_key=True)
    password = db.Column(db.String(30), nullable=False)


class WebAdmins(db.Model):
    __tablename__ = 'webadmins'
    __table_args__ = {'extend_existing': True}
    uid = db.Column(db.String(30), primary_key=True) 
    name = db.Column(db.String(100), nullable=False)

