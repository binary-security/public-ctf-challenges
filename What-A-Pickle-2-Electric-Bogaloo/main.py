import pickle
import base64
import os
from flask import request, Flask, render_template
from flask_bootstrap import Bootstrap
from flask_wtf import Form
from wtforms import TextField, SubmitField


class AddressForm(Form):
    street = TextField('Street', description='Street name and number')
    zip_code = TextField('ZIP', description='Zip code')
    city = TextField('City', description='City')

    submit_address = SubmitField('Submit Form')


class SerializedDataForm(Form):
    serialized_data = TextField('Serialized data', description='...')

    submit_data = SubmitField('Submit Form')


class Address():
    def __init__(self, street, zip_code, city):
        self.street = street
        self.zip_code = zip_code
        self.city = city

    def __repr__(self):
        return f'Street: {self.street}\nZIP: {self.zip_code}\nCity: {self.city}'


def validate_address(address):
    if not (isinstance(address.street, str) and isinstance(address.zip_code, str) and isinstance(address.city, str)):
        raise("Hackers!")


def page_not_found(e):
    return render_template('404.html'), 404


def server_error(e):
    return render_template('500.html'), 500


def create_app(configfile=None):
    app = Flask(__name__)
    Bootstrap(app)

    # in a real app, these should be configured through Flask-Appconfig
    app.config['SECRET_KEY'] = os.environ.get('FLASK_SECRET', 'devkey')

    @app.route('/', methods=['GET', 'POST'])
    def index():
        address_form = AddressForm()
        ser_form = SerializedDataForm()

        app.register_error_handler(404, page_not_found)
        app.register_error_handler(500, server_error)

        if address_form.submit_address.data and address_form.validate_on_submit():

            serialized = serialize(address_form.street.data, address_form.zip_code.data, address_form.city.data)
            return render_template('index.html', form=address_form, serform=ser_form, result=serialized.decode('utf-8'))

        elif ser_form.submit_data.data and ser_form.validate_on_submit():

            deserialized = deserialize(ser_form.serialized_data.data)

            validate_address(deserialized)

            return render_template('index.html', form=address_form, serform=ser_form, result=str(deserialized))

        else:
            return render_template('index.html', form=address_form, serform=ser_form)

    @app.route('/healthz', methods=['GET'])
    def healthz():
        return "OK"

    def serialize(street, zip_code, city):
        address = Address(street, zip_code, city)
        return base64.b64encode(pickle.dumps(address))

    def deserialize(serialized):
        address = pickle.loads(base64.b64decode(serialized))
        return address

    return app

if __name__ == '__main__':
    create_app().run(debug=False, host='0.0.0.0', port=80)
