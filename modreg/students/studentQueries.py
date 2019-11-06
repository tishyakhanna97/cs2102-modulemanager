from modreg import db, login_manager


#Modules that the student has applied for
def get_registered_modules(student_id):
    query = "SELECT * FROM Bids  WHERE uid = ('{}');".format(student_id)
    modules_student_has_registered = db.session.execute(query).fetchall()
    return modules_student_has_registered

#Modules that the student has completed
def get_completed_modules(student_id):
    query = "SELECT * FROM Completed  WHERE (uid) = ('{}');".format(student_id)
    modules_student_has_completed = db.session.execute(query).fetchall()
    return modules_student_has_completed

#Modules that the student has successfully registered for
def get_successful_modules(student_id):
    query = "SELECT * FROM Gets WHERE (uid) = ('{}');".format(student_id)
    successful_modules_student_has = db.session.execute(query).fetchall()
    return successful_modules_student_has

#Modules that are prereqs for the module the student has highlighted
def get_missing_prereq_modules(student_id, module_code):
    query = "SELECT * FROM Prerequisites" \
            "WHERE Prerequisites.modcode = ('{}')" \
            "AND" \
            "NOT EXISTS (" \
            "SELECT * " \
            "FROM " \
            "Completions" \
            "WHERE" \
            "Completions.modcode = Prequisites.prereq" \
            "AND Completions.uid = ({}))" \
            "" \
            "".format(module_code, student_id)
    missing_prereq_modules = db.session.execute(query).fetchall()
    return missing_prereq_modules
