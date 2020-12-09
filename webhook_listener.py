# To run:
# export FLASK_APP=test_webhook_listener.py
# python -m flask run

from flask import Flask, request, Response
import json

print("Hello, world!")
app = Flask(__name__)

@app.route('/webhook', methods=['POST'])
def respond():
    print("Received request:")
    print(request.json)

    print("Returning response that was same as request")
    # See https://stackoverflow.com/questions/13081532/return-json-response-from-flask-view
    # Could also use flask.jsonify, which does the same as this:
    response = app.response_class(
        # response=json.dumps(DEFAULT_RESPONSE),
        response=request.json,  # mirror the request back
        status=200,
        mimetype='application/json',
        )

    return response

