from flask import Flask, render_template, url_for, request
import subprocess
import json
import time

#STATIC VARIABLE

#RUN
app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/PullMembersOfAgroup')
def PullMembersOfAgroup():
    return render_template('PullMembersOfAgroup.html')

@app.route('/GetUserByPhoneNumber', methods=['GET', 'POST'])
def GetUserByPhoneNumber():

    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        phone_prefix = request.form.get('phone_prefix')
        phone_number = request.form.get('phone_number')
        full_number = f'{phone_prefix}{phone_number}'

        data = get_user_by_number(full_number)

        return render_template(
            'GetUserByPhoneNumber.html',
            username=username,
            password=password,
            phone_prefix=phone_prefix,
            phone_number=phone_number,
            result=data
        )
    return render_template('GetUserByPhoneNumber.html')

       

@app.route('/GetAllGroupsaUserIsaMemberOf', methods=['GET', 'POST'])
def GetAllGroupsaUserIsaMemberOf():
    return render_template('GetAllGroupsaUserIsaMemberOf.html')

@app.route('/GetChangeHistoryOfaGivenUser')
def GetChangeHistoryOfaGivenUser():
    return render_template('GetChangeHistoryOfaGivenUser.html')

@app.route('/GetChangeHistoryOfaGivenGroup')
def GetChangeHistoryOfaGivenGroup():
    return render_template('GetChangeHistoryOfaGivenGroup.html')


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

if __name__ == "__main__":
    app.run(debug=True)