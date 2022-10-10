import numpy as np

event_data = np.load("GFP_Data/numpy_data.npz")

adc_values = event_data["adc_values"]
edep_values = event_data["edep_values"]

print(event_data["adc_values", "edep_values"])

# TRANSFER FUNCTION (old)
