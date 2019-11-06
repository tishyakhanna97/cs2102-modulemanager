from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField, BooleanField
from wtforms.validators import DataRequired, Email, Length, EqualTo, ValidationError
from flask_login import current_user

class LoginForm(FlaskForm):
    # roomNumber = StringField('Room Number', validators=[DataRequired()])
    # password = PasswordField('Password', validators=[DataRequired()])
    # submit = SubmitField('Login')
    userName = StringField('Username', validators=[DataRequired()])
    password = PasswordField('Password', validators=[DataRequired()])
    submit = SubmitField('Login')
