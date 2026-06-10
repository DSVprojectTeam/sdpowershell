
import subprocess
import json
from flask import request, render_template, send_file


#=======================================FUNCTIONS=======================================================

def get_user_number_by_login(login):
    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy", "Bypass",
                "-File", ".\\Scripts\\Get-UsersPhoneNumber.ps1",
                "-SAMAccountName", login,
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
    if not group_name:
        return None
    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy", "Bypass",
                "-File", ".\\Scripts\\Get-GroupMembers.ps1",
                group_name.strip()
            ],
            capture_output=True,
            text=True,
            timeout=600,
            encoding='utf-8', # Read UTF-8
            errors='replace' # Error exception
        )

        if result.returncode != 0:
            print(f"Error {result.stderr}")
            return None

        # Stdout check
        if not result.stdout or not result.stdout.strip():
            #print("PowerShell returned empty object.")
            return None

        parsed_json = json.loads(result.stdout)
        print("Success!")
        return parsed_json

    except subprocess.TimeoutExpired:
        print("Skrypt przekroczył limit czasu.")
        return None
    except json.JSONDecodeError:
        print("Nie udało się zdekodować JSON-a.")
        print("Odpowiedź:", result.stdout if 'result' in locals() else "No result")
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
    


def get_expired_passwords(group_name): 
    if not group_name:
        return None
    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy", "Bypass",
                "-File", ".\\Scripts\\Get-GroupMembers.ps1",
                group_name.strip()
            ],
            capture_output=True,
            text=True,
            timeout=600,
            encoding='utf-8', # Read UTF-8
            errors='replace' # Error exception
        )

        if result.returncode != 0:
            print(f"Error {result.stderr}")
            return None

        # Stdout check
        if not result.stdout or not result.stdout.strip():
            #print("PowerShell returned empty object.")
            return None

        parsed_json = json.loads(result.stdout)
        print("Success!")
        return parsed_json

    except subprocess.TimeoutExpired:
        print("Skrypt przekroczył limit czasu.")
        return None
    except json.JSONDecodeError:
        print("Nie udało się zdekodować JSON-a.")
        print("Odpowiedź:", result.stdout if 'result' in locals() else "No result")
        return None