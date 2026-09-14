import os
import subprocess
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enables the web application to securely talk to this script

# Define your exact parameters matching your PowerShell file configuration
GIT_EXE = r"C:\Users\332651\Downloads\PortableGit\cmd\git.exe"

COMMAND_MAP = {
    "status": ["status"],
    "log": ["log", "--oneline", "-n", "5"],
    "branch": ["branch", "-a"],
    "remote": ["remote", "-v"]
}

@app.route('/api/git', methods=['POST'])
def execute_git_command():
    data = request.json
    cmd_type = data.get('command')
    target_path = data.get('path')

    # Security check matching your original script logic
    if not os.path.exists(target_path):
        return jsonify({"output": "Error: Target folder path does not exist."})

    if cmd_type not in COMMAND_MAP:
        return jsonify({"output": "Error: Unknown action argument requested."})

    try:
        # Replicates "Set-Location target_path" and executing the binary safely
        full_args = [GIT_EXE] + COMMAND_MAP[cmd_type]
        result = subprocess.run(
            full_args, 
            cwd=target_path, 
            stdout=subprocess.PIPE, 
            stderr=subprocess.STDOUT, 
            text=True, 
            shell=True
        )
        return jsonify({"output": result.stdout if result.stdout else "Command completed with no output."})
    except Exception as e:
        return jsonify({"output": f"Error running command:\n{str(e)}"})

if __name__ == '__main__':
    print("Retro Control Panel Backend Engine online on http://localhost:5000")
    app.run(port=5000)
