from flask import Flask, request, abort, jsonify
from sarima import predict
from dtos import TSARequest, TSAResponse, JsonRequestKeys
from checkRequest import check, loadSchema
import numpy
import statsmodels.api as sm

#modified by Fabian Wallisch WWI16

app = Flask(__name__)
#This is the file name of the schema that is used to validate time series analysis requests
schemaFileName = "requestSchema.json"

@app.route("/")
def hello():
    return "Hello World!"

@app.route("/predict", methods=['POST'])
def make_predictions():
    json = request.get_json()
    
    print(json)
    
    tsaRequest = TSARequest()
    tsaResponse = TSAResponse()
    
    try:
        #this is to validate the request
        #TODO: check the schema / validation -> each key only once, ...
        check(json, loadSchema(schemaFileName))
        
        tsaRequest.TimeSeriesValues = json[JsonRequestKeys.TimeSeriesValues.value]
        tsaRequest.PredictionSteps = json[JsonRequestKeys.PredictionSteps.value]
    except FileNotFoundError:
        abort(500, "Schema for request validation not found")
    except Exception as e:
        abort(400, str(e))
        
    try:
        tsaRequest.Order = json[JsonRequestKeys.Order.value]
        #if order is provided:
        try:
            tsaRequest.SeasonalOrder = json[JsonRequestKeys.SeasonalOrder.value]
            #if seasonal order & order are provided:
            try:
                #creating the forecast with the predict function of the sarima.py
                tsaResponse.Forecast, tsaResponse.Score, tsaResponse.Order, tsaResponse.SeasonalOrder = predict(tsaRequest.TimeSeriesValues, tsaRequest.PredictionSteps, tsaRequest.Order, seasonal_order=tsaRequest.SeasonalOrder)
            except Exception as e:
                abort(500, "Error during modeling process - " + str(e))
        except Exception as e:
            #if only order but not seasonalOrder is provided:
            try:
                #creating the forecast with the predict function of the sarima.py
                tsaResponse.Forecast, tsaResponse.Score, tsaResponse.Order, tsaResponse.SeasonalOrder = predict(tsaRequest.TimeSeriesValues, tsaRequest.PredictionSteps, tsaRequest.Order)
            except Exception as e:
                abort(500, "Error during modeling process - " + str(e))
        
    except Exception as e:
        #if order is not provided we have to estimate a suitable order using the aic
        res = sm.tsa.arma_order_select_ic(tsaRequest.TimeSeriesValues, ic=['aic'], trend='c')
        order = [int(res.aic_min_order[0]), 0, int(res.aic_min_order[1])]
        try:
            tsaRequest.SeasonalOrder = json[JsonRequestKeys.SeasonalOrder.value]
            #if seasonalOrder but not order is provided:
            try:
                #creating the forecast with the predict function of the sarima.py
                tsaResponse.Forecast, tsaResponse.Score, tsaResponse.Order, tsaResponse.SeasonalOrder = predict(tsaRequest.TimeSeriesValues, tsaRequest.PredictionSteps, order, seasonal_order=tsaRequest.SeasonalOrder)
            except Exception as e:
                abort(500, "Error during modeling process - " + str(e))
        except Exception as e:
            #if neither order nor seasonalOrder is provided:
            try:
                #creating the forecast with the predict function of the sarima.py
                tsaResponse.Forecast, tsaResponse.Score, tsaResponse.Order, tsaResponse.SeasonalOrder = predict(tsaRequest.TimeSeriesValues, tsaRequest.PredictionSteps, order)
            except Exception as e:
                abort(500, "Error during modeling process - " + str(e))
    
    #if we can not match the input order to output order if provided (e.g. because of too less observations etc.), we want to throw an exception            
    if tsaRequest.Order and not numpy.array_equal(tsaRequest.Order, tsaResponse.Order):
        abort(500, "Can't match order to requested order - use more observations - at least 17 for Brown Rozeff")
         
    if tsaRequest.SeasonalOrder and not numpy.array_equal(tsaRequest.SeasonalOrder, tsaResponse.SeasonalOrder):
        abort(500, "Can't match seasonal order to requested seasonal order - use more observations - at least 17 for Brown Rozeff")
    print("orders are correct")
          
    print(tsaResponse.Forecast)
    print(tsaResponse.Score)
    print(tsaResponse.Order)
    print(tsaResponse.SeasonalOrder)
    
    #returning the result as json in format [forecast, stderror]
    return jsonify(values=tsaResponse.Forecast, score=tsaResponse.Score, order=tsaResponse.Order, seasonalOrder = tsaResponse.SeasonalOrder)

@app.errorhandler(Exception)
def global_exception_handler(error):
    return f'{error}', 500


if __name__ == "__main__":
    app.run(debug=True)
