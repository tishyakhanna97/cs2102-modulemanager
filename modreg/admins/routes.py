import json
from flask import Blueprint, request, render_template, url_for,redirect
from modreg.admins.forms import *
from flask import Blueprint, render_template, url_for, redirect, request, flash
from flask_login import login_user, current_user, logout_user, login_required

admins = Blueprint('admins', __name__)

@admins.route("/admin/home")
def adminHome():
    return render_template('admin/home.html')
    
@admins.route("/admin/add")
def adminAdd():
    return render_template('/modreg/admin/add.html')
