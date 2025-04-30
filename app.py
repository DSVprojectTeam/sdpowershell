from flask import Flask, render_template, url_for, request
import subprocess

#STATIC VARIABLE

#RUN
app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/PullMembersOfAgroup')
def PullMembersOfAgroup():
    return render_template('PullMembersOfAgroup.html')

@app.route('/GetUserByPhoneNumber')
def GetUserByPhoneNumber():
    return render_template('GetUserByPhoneNumber.html')

@app.route('/GetAllGroupsaUserIsaMemberOf')
def GetAllGroupsaUserIsaMemberOf():
    return render_template('GetAllGroupsaUserIsaMemberOf.html')

@app.route('/GetChangeHistoryOfaGivenUser')
def GetChangeHistoryOfaGivenUser():
    return render_template('GetChangeHistoryOfaGivenUser.html')

@app.route('/GetChangeHistoryOfaGivenGroup')
def GetChangeHistoryOfaGivenGroup():
    return render_template('GetChangeHistoryOfaGivenGroup.html')

if __name__ == "__main__":
    app.run(debug=True)