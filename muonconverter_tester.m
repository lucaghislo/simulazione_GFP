
%% TEST muonconverter function

%% v1
clear; clc;
fun_out = muonconverter_v1("C:\Users\ghisl\Documents\GitHub\muon_detection_plots\input\muons\31082022\self_trigger_1hr_THR_130_pt4_34.txt", "C:\Users\ghisl\Downloads\output.pdf", 4, 0, 31, true, false, 15, 6000);
fun_out = muonconverter_v1("C:\Users\ghisl\Documents\GitHub\muon_detection_plots\input\muons\31082022\self_trigger_1hr_THR_130_pt4_34.txt", "C:\Users\ghisl\Downloads\output.pdf", 4, 16, 23);

%% v2 (WIN)
clear; clc;
fun_out = muonconverter_v2("C:\Users\ghisl\Documents\GitHub\muon_detection_plots\input\muons\31082022\self_trigger_1hr_THR_130_pt4_34.txt", "C:\Users\ghisl\Downloads\output.pdf", 4, "C:\Users\ghisl\My Drive\UniBG\CORSI\PhD\GAPS\module_muon_detection\test_results\14092022_2\data\TransferFunction_fast_tau4.dat", "C:\Users\ghisl\My Drive\UniBG\CORSI\PhD\GAPS\module_muon_detection\test_results\14092022_2\data\Pedestals_tau4.dat", 0, 31, true, true, 15, 6000);
fun_out = muonconverter_v2("C:\Users\ghisl\Documents\GitHub\muon_detection_plots\input\muons\31082022\self_trigger_1hr_THR_130_pt4_34.txt", "C:\Users\ghisl\Downloads\output", 4, "C:\Users\ghisl\My Drive\UniBG\CORSI\PhD\GAPS\module_muon_detection\test_results\14092022_2\data\TransferFunction_fast_tau4.dat", "C:\Users\ghisl\My Drive\UniBG\CORSI\PhD\GAPS\module_muon_detection\test_results\14092022_2\data\Pedestals_tau4.dat");

%% v2 (LINUX)
clear; clc;
fun_out = muonconverter_v2("/home/lucaghislotti/Documents/GitHub/lucaghislo/simulazione_GFP/fdt_lookup_table/muon_data/self_trigger_1hr_THR_130_pt4_34.txt", ...
    "/home/lucaghislotti/Downloads/risultati_misure", 4, ...
    "/home/lucaghislotti/Documents/GitHub/lucaghislo/simulazione_GFP/sample_data/MODULE_238/data/TransferFunction_fast_tau4.dat", ...
    "/home/lucaghislotti/Documents/GitHub/lucaghislo/simulazione_GFP/sample_data/MODULE_238/data/Pedestals_tau4.dat", ...
    0, 31, 15, 6000);

%% v2 (LINUX on GFP data)
clear; clc;
fun_out = muonconverter_GFP(0, 0, "/home/lucaghislotti/Documents/GitHub/lucaghislo/simulazione_GFP/GFP_Data/events/ADU/row0_mod0_allch_ADU.dat", ...
    "/home/lucaghislotti/Downloads/GFP_Row0_Module0", 4, ...
    "/home/lucaghislotti/Documents/GitHub/lucaghislo/simulazione_GFP/GFP_Data/transfer_functions", ...
    "/home/lucaghislotti/Documents/GitHub/lucaghislo/simulazione_GFP/GFP_Data/pedestal/input/row0_mod0_allch_pedestals.dat", ...
    0, 31, 15, 6000);

%% v2 (WIN on GFP data)
clear; clc;
[fun_out, landau_MPV] = muonconverter_GFP(0, 0, "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\GFP_Data\events\ADU\single_channels\", ...
    "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\output\GPF_analysis_row0_mod0", 4, ...
    "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\GFP_Data\transfer_functions", ...
    "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\GFP_Data\pedestal\input\row0_mod0_allch_pedestals.dat", ...
    0, 31, 15, 6000);

%% v2 (WIN on all GFP modules)
clear; clc;
GFP_MPVs = nan(36, 1);
module_counter = 1;
for row = [0]
    for mod = [0]
        [fun_out, landau_MPV] = muonconverter_GFP(row, mod, "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\GFP_Data\events\ADU\single_channels\", ...
            "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\output\GFP_output_2\GPF_analysis_row" + string(row) + "_mod" + string(mod), 4, ...
            "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\GFP_Data\transfer_functions", ...
            "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\GFP_Data\pedestal\input\row0_mod0_allch_pedestals.dat", ...
            0, 31, 15, 6000);
        GFP_MPVs(module_counter) = landau_MPV;
        GFP_MPVs_table = array2table(GFP_MPVs);
        writetable(GFP_MPVs_table, "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\output\GFP_output_2\landaus_MPVs.dat", 'Delimiter', "\t");
        module_counter = module_counter + 1;
    end
end

%% v2 (WIN on all GFP modules with different pedestals)
clear; clc;
GFP_MPVs = nan(36, 2);
module_counter = 1;
for row = [2:5]
    for mod = [0:5]
        [fun_out_ped, fun_out_inj, fun_out_rem, landau_MPV] = muonconverter_GFP_pedestals(row, mod, "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\GFP_Data\events\ADU\single_channels\", ...
            "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\output\GFP_output_2\GPF_analysis_row" + string(row) + "_mod" + string(mod), 4, ...
            "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\GFP_Data\transfer_functions", ...
            "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\GFP_Data\pedestal\input\row0_mod0_allch_pedestals.dat", ...
            0, 31, 15, 6000);
        GFP_MPVs(module_counter) = landau_MPV;
        GFP_MPVs_table = array2table(GFP_MPVs);
        writetable(GFP_MPVs_table, "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\output\GFP_output_2\landaus_MPVs.dat", 'Delimiter', "\t");
        module_counter = module_counter + 1;
    end
end

%% v2 (true pedestals)
clear; clc;
fun_out = muonconverter_v2("C:\Users\ghisl\Documents\GitHub\muon_detection_plots\input\muons\31082022\self_trigger_1hr_THR_130_pt4_34.txt", ...
    "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\output\GFP_true_pedestal", 4, ...
    "C:\Users\ghisl\My Drive\UniBG\CORSI\PhD\GAPS\module_muon_detection\test_results\14092022_2\data\TransferFunction_fast_tau4.dat", ...
    "C:\Users\ghisl\My Drive\UniBG\CORSI\PhD\GAPS\module_muon_detection\test_results\14092022_2\data\Pedestals_tau4.dat", ...
    0, 31, 15, 6000);

%% v3 (two pedestals)
clear; clc;
fun_out = muonconverter_v3_twoped("C:\Users\ghisl\Documents\GitHub\muon_detection_plots\input\muons\31082022\self_trigger_1hr_THR_130_pt4_34.txt", ...
    "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\output\GFP_two_pedestals", 4, ...
    "C:\Users\ghisl\My Drive\UniBG\CORSI\PhD\GAPS\module_muon_detection\test_results\14092022_2\data\TransferFunction_fast_tau4.dat", ...
    "C:\Users\ghisl\My Drive\UniBG\CORSI\PhD\GAPS\module_muon_detection\test_results\14092022_2\data\Pedestals_tau4.dat", ...
    0, 31, 15, 6000);

%% v3 (GFP pedestals)
clear; clc;
fun_out = muonconverter_v3_twoped("C:\Users\ghisl\Documents\GitHub\muon_detection_plots\input\muons\31082022\self_trigger_1hr_THR_130_pt4_34.txt", ...
    "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\output\GFP_two_pedestals", 4, ...
    "C:\Users\ghisl\My Drive\UniBG\CORSI\PhD\GAPS\module_muon_detection\test_results\14092022_2\data\TransferFunction_fast_tau4.dat", ...
    "C:\Users\ghisl\My Drive\UniBG\CORSI\PhD\GAPS\module_muon_detection\test_results\14092022_2\data\Pedestals_tau4.dat", ...
    0, 31, 15, 6000);

%% v2 (true pedestals on Napoli module)
clear; clc;
fun_out = muonconverter_v2("C:\Users\ghisl\Documents\GitHub\simulazione_GFP\sample_data\self_trigger_THR_150_fthr_napoli.txt", ...
    "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\output\napoli", 6, ...
    "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\sample_data\MODULE_Napoli\1\data\TransferFunction_fast_tau6.dat", ...
    "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\sample_data\MODULE_Napoli\1\data\Pedestals_tau6.dat", ...
    0, 31, 15, 6000);


%% v2 (true pedestals) - GAPS @ SSL
clear; clc;
fun_out = muonconverter_v2("file muoni in CSV", ...
    "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\output\SSL_Berkeley", 5, ...
    "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\sample_data\MODULE_001\IT_L0R0M1_m25.8C\data\TransferFunction.dat", ...
    "C:\Users\ghisl\Documents\GitHub\simulazione_GFP\sample_data\MODULE_001\IT_L0R0M1_m25.8C\data\Pedestals.dat", ...
    0, 31, 15, 6000);
