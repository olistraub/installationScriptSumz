from enum import Enum

class JsonRequestKeys(Enum):
    TimeSeriesValues = 'values'
    PredictionSteps = 'predSteps'
    Order = 'order'
    SeasonalOrder = 'seasonalOrder'
    
class TSARequest():
    
    def __init__(self):
        self.TimeSeriesID = ""
        self.TimeSeriesValues = []
        self.PredictionSteps = 0
        self.Order = []
        self.SeasonalOrder = []
    
class TSAResponse():
    
    def __init__(self):
        self.Forecast = []
        self.score = 0.0
        self.Order = []
        self.SeasonalOrder = []
