import sqlalchemy
import enum
from sqlalchemy.types import UserDefinedType

from flask import current_app
from modreg import db
from datetime import datetime
from flask_user import roles_required, UserMixin


class WebUsers(db.Model):
    """ defines table name """
    __tablename__ = 'webusers'
    __table_args__ = {'extend_existing': True}

    """ defines attributes """
    uid = db.Column(db.String(30), primary_key=True)
    password = db.Column(db.String(30), nullable=False)
    # is super field determines if this uer is an admin
    is_super = db.Column(db.Boolean, nullable=False, default=False)

    """ defines relationships and cascade delete constraints """
    students = db.relationship("Students", cascade="all,delete")
    webadmins = db.relationship("WebAdmins", cascade="all,delete")
    bids = db.relationship("Bids", cascade="all,delete")

class WebAdmins(db.Model):
    """ defines table name """
    __tablename__ = 'webadmins'
    __table_args__ = {'extend_existing': True}

    """ defines attributes """
    # UID serves as a primary key as well as a FK which references webuser table
    uid = db.Column(db.String(30), db.ForeignKey(
        'webusers.uid'), primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    contact = db.Column(db.String(100))


class Students(db.Model):
    """ defines table name """
    __tablename__ = 'students'
    __table_args__ = {'extend_existing': True}

    """ defines attributes """
    # UID serves as a primary key as well as a FK which references webuser table
    uid = db.Column(db.String(30), db.ForeignKey(
        'webusers.uid'), primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    enroll = db.Column(db.Date, nullable=False)

    """ defines relationships and cascade delete constraints """
    exchanges = db.relationship("Exchanges", cascade="all,delete")
    minoring = db.relationship("Minoring", cascade="all, delete, save-update")
    bids = db.relationship("Bids", cascade="all, delete, save-update")
    gets = db.relationship("Gets", cascade="all, delete, save-update")
    completions = db.relationship(
        "Completions", cascade="all, delete, save-update")


class Exchanges(db.Model):
    """ defines table name """
    __tablename__ = 'exchanges'
    __table_args__ = {'extend_existing': True}

    """ defines attributes """
    # UID serves as a primary key as well as a FK which references webuser table
    uid = db.Column(db.String(30), db.ForeignKey(
        'webusers.uid'), primary_key=True)
    home_country = db.Column(db.String(100), nullable=False)


class Faculties(db.Model):
    """ defines table name """
    __tablename__ = 'faculties'
    __table_args__ = {'extend_existing': True}

    """ defines attributes """
    fname = db.Column(db.String(100), primary_key=True)

    """ defines relationships """
    # passive_deletes -> sets the fname in affected minors/majors to default
    minors = db.relationship(
        "Minors", passive_deletes="all", cascade="save-update")
    majors = db.relationship(
        "Majors", passive_deletes="all", cascade="save-update")
    modules = db.relationship(
        "Modules", passive_deletes="all", cascade="save-update")


class Minors(db.Model):
    """ defines table name """
    __tablename__ = 'minors'
    __table_args__ = {'extend_existing': True}

    """ defines attributes """
    min_name = db.Column(db.String(100), primary_key=True)
    fname = db.Column(db.String(100), db.ForeignKey(
        'faculties.fname'), default='NUS')

    """ defines relationships """
    minoring = db.relationship("Minoring", cascade="all, delete, save-update")


class Majors(db.Model):
    """ defines table name """
    __tablename__ = 'majors'
    __table_args__ = {'extend_existing': True}

    """ defines attributes """
    maj_name = db.Column(db.String(100), primary_key=True)
    fname = db.Column(db.String(100), db.ForeignKey(
        'faculties.fname'), default='NUS')


class Minoring(db.Model):
    """ defines table name """
    __tablename__ = 'minoring'
    __table_args__ = {'extend_existing': True}

    """ defines attributes """
    uid = db.Column(db.String(30), db.ForeignKey(
        'webusers.uid'), primary_key=True)
    min_name = db.Column(db.String(100), db.ForeignKey(
        'minors.min_name'), primary_key=True)


class Majoring(db.Model):
    """ defines table name """
    __tablename__ = 'majoring'
    __table_args__ = {'extend_existing': True}

    """ defines attributes """
    uid = db.Column(db.String(30), db.ForeignKey(
        'webusers.uid'), primary_key=True)
    maj_name = db.Column(db.String(100), db.ForeignKey(
        'majors.maj_name'), primary_key=True)


class Modules(db.Model):
    """ defines table name """
    __tablename__ = 'modules'
    __table_args__ = {'extend_existing': True}

    """ defines attributes """
    modcode = db.Column(db.String(100), primary_key=True)
    modname = db.Column(db.String(100), nullable=False)
    descriptions = db.Column(db.Text)
    fname = db.Column(db.String(100), db.ForeignKey(
        'faculties.fname'), default='NUS')
    workload = db.Column(db.Integer, nullable=False)

    """ defines relationships """
    lectures = db.relationship("Lectures", passive_deletes="all")
    prerequisites = db.relationship("Prerequisites", cascade="all, delete")
    preclusions = db.relationship("Preclusions", cascade="all, delete")


class Lectures(db.Model):
    """ defines table name """
    __tablename__ = 'lectures'
    __table_args__ = {'extend_existing': True}

    """ defines attributes """
    lnum = db.Column(db.Integer, primary_key=True)
    modcode = db.Column(db.String(100), db.ForeignKey(
        'modules.modcode'), primary_key=True)
    quota = db.Column(db.Integer, nullable=False)
    deadline = db.Column(db.DateTime, nullable=False)

    """ defines relationship """
    slots = db.relationship("Slots", cascade="all")
    bids = db.relationship("Bids", cascade="all, delete")
    gets = db.relationship("Gets", cascade="all, delete")


class Slots(db.Model):
    """ defines table name and arguments"""
    __tablename__ = 'slots'
    __table_args__ = {'extend_existing': True}

    """ defines attributes """
    lnum = db.Column(db.Integer, primary_key=True)
    modcode = db.Column(db.String(100), primary_key=True)
    t_start = db.Column(db.Time, db.CheckConstraint('t_end > t_start'))
    t_end = db.Column(db.Time)
    day = db.Column(db.String(10), primary_key=True)
    db.ForeignKeyConstraint([lnum, modcode], [Lectures.lnum, Lectures.modcode])


class Prerequisites(db.Model):
    """ defines table name and arguments"""
    __tablename__ = 'prerequisites'
    __table_args__ = {'extend_existing': True}

    """ defines attributes and key constraints"""
    modcode = db.Column(db.String(100), db.ForeignKey(
        'modules.modcode'), db.CheckConstraint('modcode <> prereq'), primary_key=True)
    prereq = db.Column(db.String(100), db.ForeignKey(
        'modules.modcode'), primary_key=True)


class Preclusions(db.Model):
    """ defines table name and arguments"""
    __tablename__ = 'preclusions'
    __table_args__ = {'extend_existing': True}

    """ defines attributes and key constraints"""
    modcode = db.Column(db.String(100), db.ForeignKey(
        'modules.modcode'), db.CheckConstraint('modcode <> precluded'), primary_key=True)
    precluded = db.Column(db.String(100), db.ForeignKey(
        'modules.modcode'), primary_key=True)


class Bids(db.Model):
    """ defines table name and arguments"""
    __tablename__ = 'bids'
    __table_args__ = {'extend_existing': True}

    """ defines attributes and key constraints"""
    uid = db.Column(db.String(30), db.ForeignKey(
        'students.uid'), primary_key=True)
    modcode = db.Column(db.String(100), nullable=False, primary_key=True)
    lnum = db.Column(db.Integer, nullable=False, primary_key=True)
    status = db.Column(db.Boolean, default=True)
    bid_time = db.Column(db.DateTime, primary_key=True)
    remark = db.Column(db.String(100), default="Successful bid!")
    db.ForeignKeyConstraint([lnum, modcode], [Lectures.lnum, Lectures.modcode])


class Gets(db.Model):
    """ defines table name and arguments"""
    __tablename__ = 'gets'
    __table_args__ = {'extend_existing': True}

    """ defines attributes and key constraints """
    uid = db.Column(db.String(30), db.ForeignKey(
        'students.uid'), primary_key=True)
    uid_adder = db.Column(db.String(30), db.ForeignKey(
        'webusers.uid'), primary_key=True)
    modcode = db.Column(db.String(100), nullable=False, primary_key=True)
    lnum = db.Column(db.Integer, nullable=False, primary_key=True)
    is_audit = db.Column(db.Boolean, default=False)
    db.ForeignKeyConstraint([lnum, modcode], [Lectures.lnum, Lectures.modcode])


class Completions(db.Model):
    """ defines table name and arguments"""
    __tablename__ = 'completions'
    __table_args__ = {'extend_existing': True}

    """ defines attributes and key constraints """
    uid = db.Column(db.String(30), db.ForeignKey(
        'students.uid'), primary_key=True)
    modcode = db.Column(db.String(100), db.ForeignKey(
        'modules.modcode'), nullable=False, primary_key=True)
