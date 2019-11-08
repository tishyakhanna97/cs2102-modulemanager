import json
from flask import Blueprint, request, render_template, url_for,redirect
from modreg.studentUsers.forms import *
from flask import Blueprint, render_template, url_for, redirect, request, flash
from flask_login import login_user, current_user, logout_user, login_required

studentUsers = Blueprint('studentUsers', __name__)

@studentUsers.route("/myhome")
#@login_required
def studentHome():
    return render_template('studentUsers/home.html')

@studentUsers.route("/mymodules")
#@login_required
def viewModules():
    return render_template('studentUsers/viewModules.html')
    
@studentUsers.route("/mybids")
def viewBids():
    return render_template('studentUsers/viewBids.html')

@studentUsers.route("/myclass")
def viewClasses():
    return render_template('studentUsers/viewClasses.html')

