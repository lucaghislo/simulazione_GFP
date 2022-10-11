import numpy as np

# EVENT DATA ACQUISITION
event_data = np.load("GFP_Data/numpy_data.npz")
adc_values = event_data["adc_values"]
edep_values = event_data["edep_values"]

# print(adc_values[:, 0, 0, :])

file = open("GFP_Data/events/row0_mod0_allch.dat", "w+")

for ch in range(0, 32):
    array = np.array(adc_values[:, 0, 0, ch])

    count = 0
    list = []
    for e in array:
        if e != 0:
            count = count + 1
            list.append(e)

    for item in list:
        file.write(str(item) + ", ")

    file.write("\n")
