import flask_wtf
import wtforms
from wtforms.validators import DataRequired, Email, Length, EqualTo, ValidationError



class RegisterForm(flask_wtf.FlaskForm):
    #Login required
    module = wtforms.StringField("Module Code", validators=[DataRequired()])
    submit = wtforms.SubmitField("Register")
