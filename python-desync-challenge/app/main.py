from flask import Flask, request, render_template
import os

def page_not_found(e):
          return render_template('404.html'), 404

def server_error(e):
          return render_template('500.html'), 500

app = Flask(__name__)
app.debug = True
app.register_error_handler(404, page_not_found)
app.register_error_handler(500, server_error)

@app.route('/', methods=['GET', 'POST'])
def main():
    # Support Transfer-Encoding
    #request.environ['wsgi.input_terminated'] = True
    return render_template('index.html')

@app.route('/healthz', methods=['GET'])
def healthz():
    return "OK"

@app.route('/forbidden', methods=['GET'])
def healthz():
    return "ILLEGAL!", 403
    
@app.route('/flag', methods=['GET'])
def flag():
    flag = os.environ.get('FLAG', 'fake_flag')
    return flag


if __name__ == "__main__":
    app.run(debug=False, use_debugger=False, use_reloader=False, passthrough_errors=True)

