
# Import packages
import pyspark
from pyspark.mllib.regression import LabeledPoint
from pyspark import SparkContext, SparkConf
from pyspark.sql.session import SparkSession
import findspark
from pyspark.ml.classification import LogisticRegression, LogisticRegressionModel
from pyspark.ml.linalg import SparseVector, VectorUDT, DenseVector
from pyspark.sql.types import StructType, StructField, FloatType, DoubleType
from pyspark.sql import Row
findspark.init()

from flask import Flask, render_template, request
app = Flask(__name__)

spark = SparkSession.builder \
        .master("local")\
        .appName("IrisModel")\
        .getOrCreate()

sc = spark.sparkContext

model = LogisticRegressionModel.load('dockerMl')

@app.route('/result',methods = ['POST', 'GET'])
def result():

    
    
    if request.method == 'POST':
        result = request.form
        d = {index:value[1] for index,value in enumerate(result.items())}
        result_vector = SparseVector(len(result), d)
        predict_df = sc.parallelize([(45.0, result_vector)])
        schema = StructType([
        StructField("label", DoubleType(), True),
        StructField("features", VectorUDT(), True)
        ])

        predict_df.toDF(schema).printSchema()

        temp_rdd_dense = predict_df.map(lambda x: Row(label=x[0],features=DenseVector(x[1].toArray())))

        final = temp_rdd_dense.toDF()

        predictions = model.transform(final)

        preds = predictions.select('probability').take(1)[0][0]

        result =  {"Setosa": preds[0], "Versicolor": preds[1],
            "Virginica": preds[2]}

        return render_template("result.html",result = result)



if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)