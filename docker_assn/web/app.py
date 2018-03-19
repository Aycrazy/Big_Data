from flask import Flask, render_template, request
app = Flask(__name__)

@app.route('/')
def iris():
    if request.method == 'POST':
      result = request.form
    return render_template('iris.html')

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True)