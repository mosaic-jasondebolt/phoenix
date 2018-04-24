from flask import Flask
from flask import jsonify
import os

app = Flask(__name__)

@app.route('/')
def hello_world():
    return jsonify(os.environ)

if __name__ == '__main__':
    app.run(debug=True,host='0.0.0.0')
