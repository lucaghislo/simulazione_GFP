import numpy as np

# PEDESTAL DATA ACQUISITION
pedestal_data = np.load("GFP_Data/pedestals_numpy.npz")
pedestal_values = pedestal_data["pedestals"]

for row in range(0, 6):
    for mod in range(0, 6):
        file = open(
            "GFP_Data/pedestal/row"
            + str(row)
            + "_mod"
            + str(mod)
            + "_allch_pedestals.dat",
            "w+",
        )

        for ch in range(0, 32):
            count = 0
            list = []

            e = pedestal_values[row, mod, ch]

            count = count + 1
            list.append(e)

            for item in list:
                file.write(str(item) + ", ")

            file.write("\n")
