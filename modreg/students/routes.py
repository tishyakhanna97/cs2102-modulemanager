import json
from flask import Blueprint, request, render_template, url_for,redirect
from modreg.students.forms import *
from flask import Blueprint, render_template, url_for, redirect, request, flash
from flask_login import login_user, current_user, logout_user, login_required

students = Blueprint('students', __name__)

@students.route("/myhome")
#@login_required
def studentHome():
    return render_template('students/home.html')

@students.route("/mymodules")
#@login_required
def viewModules():
    return render_template('students/viewModules.html')
    
@students.route("/mybids")
def viewBids():
    return render_template('students/viewBids.html')

@students.route("/myclass")
def viewClasses():
    return render_template('students/viewClasses.html')

