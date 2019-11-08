import json
from flask import Blueprint, request, render_template, url_for,redirect
from modreg.main.forms import *
from flask import Blueprint, render_template, url_for, redirect, request, flash
from flask_login import login_user, current_user, logout_user, login_required
from modreg.models import WebUsers
from modreg import db

main = Blueprint('main', __name__)

@main.route("/")
@main.route("/home")
def home():
    user = db.engine.execute("SELECT * FROM webuser")
    return render_template('main/home.html', user=user)
    
@main.route("/")
@main.route("/faqpage")
def faq():
    return render_template('/main/faq.html')

@main.route("/login", methods=['GET','POST']) 
def login():
    form = LoginForm()
    if form.validate_on_submit():
        attemptedWebUser = WebUsers.query.filter_by(uid=form.userName.data).first()
        #if user and bcrypt.check_password_hash(user.password, form.password.data):
        if attemptedWebUser and form.password.data == attemptedWebUser.password:
            login_user(attemptedWebUser)
            next_page = request.args.get('next')
            return redirect(next_page) if next_page else redirect(url_for('main.home'))
        else:
            flash('Login Unsuccessful, Please Check room number and password', 'danger')
    return render_template('/main/login.html', title='Login', form=form)


@main.route("/logout", methods=['GET','POST']) 
def logout():
    logout_user()
    return redirect(url_for('main.home'))