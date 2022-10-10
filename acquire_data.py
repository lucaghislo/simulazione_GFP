import numpy as np

transfer_fun_data = np.load("GFP_Data/numpy_data.npz")

adc_values = transfer_fun_data["adc_values"]
edep_values = transfer_fun_data["edep_values"]

print(adc_values)
