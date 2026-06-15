from flask import Flask, render_template, url_for, request
from helpers import get_all_groups_of_user , group_audit , get_expiring_passwords , get_group_members , get_user_by_number , get_user_number_by_login
import json
import os
import tempfile
import csv
from flask import request, render_template, send_file


#STATIC VARIABLE
#RUN
app = Flask(__name__)

@app.route('/')
def index():
    return render_template("index.html")

#======================GET_GROUP_MEMBERS=========================================
@app.route("/PullMembersOfAgroup", methods=["GET", "POST"])
def PullMembersOfAgroup():
    if request.method == "POST":
        group_name = request.form.get("group_name")

        data = get_group_members(group_name)

        final_result = {}

        # Safely handle the data returned from PowerShell
        if isinstance(data, dict):
            # If data is already a dictionary, use it directly
            final_result = data
        elif isinstance(data, str) and data.strip():
            # If data is a string, try to parse it as JSON
            try:
                final_result = json.loads(data)
            except Exception as e:
                final_result = {"Error": f"Unable to parse data: {data}"}
        else:
            # If data is None or empty string
            final_result = {"Error": "Script did not return any data."}


        return render_template(
            "PullMembersOfAgroup.html",
            group_name=group_name,
            result=final_result,
        )
    return render_template("PullMembersOfAgroup.html")


#==========================FIND_USER_BY_PHONE=============================================

@app.route('/GetUserByPhoneNumber', methods=['GET', 'POST'])
def GetUserByPhoneNumber():

    if request.method == 'POST':
        phone_number = request.form.get('phone_number')
        full_number = f'{phone_number}'

        data = get_user_by_number(full_number)

        return render_template(
            'GetUserByPhoneNumber.html',
            phone_number=phone_number,
            result=data
        )
    return render_template('GetUserByPhoneNumber.html')


@app.route("/GetAllGroupsaUserIsaMemberOf", methods=["GET", "POST"])
def GetAllGroupsaUserIsaMemberOf():
    if request.method == "POST":
        searched_user = request.form.get("searched_user")
        
        data = get_all_groups_of_user(searched_user)
        
        return render_template(
            "GetAllGroupsaUserIsaMemberOf.html",
            searched_user=searched_user,
            result=data,
        )
    return render_template("GetAllGroupsaUserIsaMemberOf.html")

#====================================FIND_USER_PHONE_NUMBER============================================

@app.route('/GetUserNumberByLogin', methods=['GET', 'POST'])
def GetUserNumberByLogin():

    if request.method == 'POST':
        searched_login = request.form.get('searched_login')

        # Execute PowerShell script via helper function
        data = get_user_number_by_login(searched_login )

        final_result = {}

        # Safely handle the data returned from PowerShell
        if isinstance(data, dict):
            # If data is already a dictionary, use it directly
            final_result = data
        elif isinstance(data, str) and data.strip():
            # If data is a string, try to parse it as JSON
            try:
                final_result = json.loads(data)
            except Exception as e:
                final_result = {"Error": f"Unable to parse data: {data}"}
        else:
            # If data is None or empty string
            final_result = {"Error": "Script did not return any data."}

        # Return the results for POST request
        return render_template(
            'GetUserNumberByLogin.html',
            searched_login=searched_login,
            result=final_result
        )

    # ---------------------------------------------------------
    # Handle GET request (when user just opens or refreshes the page)
    # THIS MUST BE OUTSIDE THE 'if request.method == "POST":' BLOCK
    # ---------------------------------------------------------
    return render_template('GetUserNumberByLogin.html', result=None)

#===============================Group_AUDIT====================================
@app.route('/GroupAudit', methods=["GET", "POST"])
def GroupAudit():
    if request.method == "POST":
        group_name = request.form.get("group_name")
        
        data = group_audit(group_name)
        
        return render_template(
            "GroupAudit.html",
            group_name=group_name,
            result=data,
        )
    # Pass result explicitly as None on GET
    return render_template('GroupAudit.html', result=None)


#===========================MASS_GROUP_AUDIT=================================================


@app.route('/MassAudit', methods=["GET", "POST"])
def MassAudit():
    if request.method == "POST":
        uploaded_file = request.files.get('file')
        if not uploaded_file:
            return render_template('MassAudit.html', result=None)

        # Save file to temp location
        temp_dir = tempfile.gettempdir()
        temp_path = os.path.join(temp_dir, uploaded_file.filename)
        uploaded_file.save(temp_path)

        results = []
        with open(temp_path, newline='', encoding='utf-8') as csvfile:
            reader = csv.reader(csvfile)
            for row in reader:
                if row:  # skip empty lines
                    group_name = row[0].strip()
                    audit_result = group_audit(group_name)
                    results.append({group_name: audit_result})

        return render_template("MassAudit.html", file=uploaded_file.filename, result=results)

    return render_template('MassAudit.html', result=None)


#=========================EXPIRING_PASSWORDS=================================== 

@app.route("/ExpiringPasswords", methods=["GET", "POST"])
def ExpiringPasswords():
    if request.method == "POST":
        # Скрипт не требует аргументов, поэтому просто вызываем функцию
        data = get_expiring_passwords()
        
        final_result = {}
        
        if data:
            # Так как helpers.py уже возвращает распарсенный JSON (словарь), 
            # просто передаем его дальше
            final_result = data
        else:
            final_result = {"Error": "Script did not return any data or an error occurred."}
            
        # ОЧЕНЬ ВАЖНО: возвращаем правильный шаблон!
        return render_template(
            "ExpiringPasswords.html",
            result=final_result
        )
        
    # Если это GET-запрос (пользователь просто открыл страницу)
    return render_template("ExpiringPasswords.html")


#===============================================================================
if __name__ == "__main__":
    app.run(debug=True)
