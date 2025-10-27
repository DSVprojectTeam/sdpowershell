from flask import Flask, render_template, url_for, request
import subprocess
import json
import time
import os
import tempfile
import csv
import shlex

#STATIC VARIABLE

#RUN
app = Flask(__name__)

@app.route('/')
def index():
    return render_template("index.html")


@app.route("/PullMembersOfAgroup", methods=["GET", "POST"])
def PullMembersOfAgroup():
    if request.method == "POST":
        group_name = request.form.get("group_name")

        data = get_group_members(group_name)

        return render_template(
            "PullMembersOfAgroup.html",
            group_name=group_name,
            result=data,
        )
    return render_template("PullMembersOfAgroup.html")


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

@app.route('/GetUserNumberByLogin', methods=['GET', 'POST'])
def GetUserNumberByLogin():
    if request.method == 'POST':
        ad_username = request.form.get('ad_username')
        ad_password = request.form.get('ad_password')
        searched_login = request.form.get('searched_login')

        if not ad_username or not ad_password or not searched_login:
            return render_template(
                'GetUserNumberByLogin.html',
                searched_login=searched_login,
                result="Brak wymaganych danych."
            )

        data = get_user_number_by_login(searched_login, ad_username, ad_password)

        return render_template(
            'GetUserNumberByLogin.html',
            searched_login=searched_login,
            result=data if data else "Necessary data is missing or the issue has occured."
        )
    return render_template('GetUserNumberByLogin.html', searched_login=None, result=None)

def get_user_number_by_login(login, ad_username, ad_password):
    try:
        prefix = "DSV\\"
        prefixed_ad_username = prefix + ad_username
        print(prefixed_ad_username)
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy", "Bypass",
                "-File", ".\\Scripts\\Get-UsersPhoneNumber.ps1",
                "-SAMAccountName", login,
                "-ADUsername", prefixed_ad_username,
                "-ADPassword", ad_password
            ],
            capture_output=True,
            text=True,
            timeout=30,
        )

        if result.returncode != 0:
            print(f"Error {result.stderr}")
            return None

        return json.loads(result.stdout)

    except subprocess.TimeoutExpired:
        print("Skrypt przekroczył limit czasu.")
        return None
    except json.JSONDecodeError:
        print("Nie udało się zdekodować JSON-a.")
        print("Odpowiedź:", result.stdout)
        return None



def group_audit(group_name):
    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                ".\\Scripts\\Audit_Group.ps1",
                group_name,
            ],
            capture_output=True,
            text=True,
            encoding='latin1',  
            timeout=260,
        )
        if result.returncode != 0:
            print(f"Error {result.stderr}")
            return None
        users_data = json.loads(result.stdout)
        print(users_data)
        return {"users": users_data}
    except subprocess.TimeoutExpired:
        print("Skrypt przekroczył limit czasu.")
        return None
    except json.JSONDecodeError:
        print("Nie udało się zdekodować JSON-a.")
        print("Odpowiedź:", result.stdout)
        return None
    

def get_group_members(group_name):
    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                ".\\Scripts\\Get-GroupMembers.ps1",
                group_name,
            ],
            capture_output=True,
            text=True,
            timeout=30,
        )

        if result.returncode != 0:
            print(f"Error {result.stderr}")
            return None
        print(json.loads(result.stdout))
        return json.loads(result.stdout)

    except subprocess.TimeoutExpired:
        print("Skrypt przekroczył limit czasu.")
        return None
    except json.JSONDecodeError:
        print("Nie udało się zdekodować JSON-a.")
        print("Odpowiedź:", result.stdout)
        return None


def get_user_by_number(phone_number):
    try:
        result = subprocess.run(["powershell", "-ExecutionPolicy", "Bypass", "-File", ".\\Scripts\\Get-UserByNumber.ps1", phone_number], capture_output=True, text=True, timeout=30)

        if result.returncode != 0:
            print(f'Error {result.stderr}')
            return None
        print(json.loads(result.stdout))
        return json.loads(result.stdout)
    
    except subprocess.TimeoutExpired:
        print("Skrypt przekroczył limit czasu.")
        return None
    except json.JSONDecodeError:
        print("Nie udało się zdekodować JSON-a.")
        print("Odpowiedź:", result.stdout)
        return None

def get_all_groups_of_user(user_name):

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                ".\\Scripts\\Get-Groupsofuser.ps1",
                user_name,
            ],
            capture_output=True,
            text=True,
            timeout=300,
        )

        if result.returncode != 0:
            print(f"Error {result.stderr}")
            return None
        print(json.loads(result.stdout))
        return json.loads(result.stdout)

    except subprocess.TimeoutExpired:
        print("Skrypt przekroczył limit czasu.")
        return None
    except json.JSONDecodeError:
        print("Nie udało się zdekodować JSON-a.")
        print("Odpowiedź:", result.stdout)
        return None

#Awaiting script
def get_change_history_of_user(user_name):
    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                ".\\Scripts\\Get-UserChangeHistory.ps1",
                user_name,
            ],
            capture_output=True,
            text=True,
            timeout=30,
        )

        if result.returncode != 0:
            print(f"Error {result.stderr}")
            return None
        print(json.loads(result.stdout))
        return json.loads(result.stdout)

    except subprocess.TimeoutExpired:
        print("Skrypt przekroczył limit czasu.")
        return None
    except json.JSONDecodeError:
        print("Nie udało się zdekodować JSON-a.")
        print("Odpowiedź:", result.stdout)
        return None

def get_change_history_of_group(group_name):
    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                ".\\Scripts\\Audit_Group.ps1",
                group_name,
            ],
            capture_output=True,
            text=True,
            timeout=30,
        )

        if result.returncode != 0:
            print(f"Error {result.stderr}")
            return None
        print(json.loads(result.stdout))
        return json.loads(result.stdout)

    except subprocess.TimeoutExpired:
        print("Skrypt przekroczył limit czasu.")
        return None
    except json.JSONDecodeError:
        print("Nie udało się zdekodować JSON-a.")
        print("Odpowiedź:", result.stdout)
        return None

if __name__ == "__main__":
    app.run(debug=True)
