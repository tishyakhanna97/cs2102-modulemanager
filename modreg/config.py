import os

#config database uri here
class Config:
    SECRET_KEY = 'c9970460fc2c3ad324add53c94e3bc2a'
    SQLALCHEMY_DATABASE_URI = 'postgres://postgres:password@localhost:5432/cs2102project'
    USER_APP_NAME = "CS2102 Project"      # Shown in and email templates and page footers
    USER_EMAIL_SENDER_EMAIL = "somedummy@gmail.com" #not used but required to initialize app