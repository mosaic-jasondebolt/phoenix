from flask import Flask
from flask import jsonify
import os
import copy

app = Flask(__name__)

@app.route('/')
def hello_world():
    return jsonify({
        'MESSAGE': 'Hello',
        'HOSTNAME': os.environ['HOSTNAME'],
        'HOME': os.environ['HOME']
    })

if __name__ == '__main__':
    app.run(debug=True,host='0.0.0.0')
