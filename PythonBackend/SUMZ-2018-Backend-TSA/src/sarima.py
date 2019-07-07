from numpy import *
import statsmodels.api as sm
from statsmodels.tsa.statespace.sarimax import SARIMAX
from pmdarima import *
from scipy.stats import norm

#created by Fabian Wallisch WWI16

def predict(timeSeriesValues, pred_steps, order, **kwargs):
    
    seasonal_order = kwargs.get('seasonal_order', None)
    
    #define the sarimax model; last param of seasonal order is frequency, e.g. 12=monthly
    if seasonal_order is None:
        model = SARIMAX(timeSeriesValues, order=order, enforce_stationarity=False, enforce_invertibility=False, trend='c')
    if seasonal_order is not None:
        model = SARIMAX(timeSeriesValues, order=order, seasonal_order=seasonal_order, enforce_stationarity=False, enforce_invertibility=False, trend='c')
    
    #alternative arima method 
    #model = pmdarima.arima.ARIMA(timeSeriesValues, order=order, seasonal_order=seasonalOrder, with_intercept=True)
    
    #fitting the model, i.e. estimating the parameters
    model_fit = model.fit()
        
    #printing a summary of the model to the console
    print(model_fit.summary())
    
    fcast = model_fit.get_forecast(pred_steps)

    print(fcast.predicted_mean)
    print(fcast.conf_int())
    
    #the score is represented by the AIC value
    score = model_fit.aic
    
    #stdError formula:
    #stdError = (fcast.conf_int()[0][1] - fcast.conf_int()[0][0]) / (2 * norm.ppf(0.5 + 95 / 200))
    
    w, h = 2, pred_steps;
    fcastWithStdErrors = [[0 for x in range(w)] for y in range(h)] 
    
    #array with [forecast, stderror]
    for i in range(len(fcast.predicted_mean)):
        print(i)
        fcastWithStdErrors[i][0] = fcast.predicted_mean[i]
        #calculation of the stderror
        fcastWithStdErrors[i][1] = (fcast.conf_int()[i][1] - fcast.conf_int()[i][0]) / (2 * norm.ppf(0.5 + 95 / 200))
        
    return fcastWithStdErrors, score, model.order, model.seasonal_order
