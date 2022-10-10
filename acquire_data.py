import numpy as np

# TRANSFER FUNCTION (old)


# EVENT DATA ACQUISITION
event_data = np.load("GFP_Data/numpy_data.npz")
adc_values = event_data["adc_values"]
edep_values = event_data["edep_values"]

print(edep_values)
# print(event_data["adc_values", "edep_values"])

data = np.load("GFP_Data/numpy_data.npz")
for key, value in data.items():
    np.savetxt("output/" + key + ".csv", value)
