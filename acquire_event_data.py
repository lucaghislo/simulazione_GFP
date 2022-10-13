import numpy as np

# EVENT DATA ACQUISITION
event_data = np.load("GFP_Data/numpy_data.npz")
adc_values = event_data["adc_values"]
edep_values = event_data["edep_values"]

for row in range(0, 6):
    for mod in range(0, 6):
        file = open(
            "GFP_Data/events/ADU/row" + str(row) + "_mod" + str(mod) + "_allch_ADU.dat",
            "w+",
        )

        for ch in range(0, 32):
            array = np.array(adc_values[:, row, mod, ch])
            count = 0
            list = []
            for e in array:
                if e != 0:
                    count = count + 1
                    list.append(e)

            if len(list) > 0:
                for item in list:
                    file.write(str(item) + ", ")

            file.write("\n")
