clear;
clc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CHOSEN INPUTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Vin_min      = 12;        % Minimum input voltage [V]
Vin_max      = 56;        % Maximum input voltage [V]
Vout_min     = 5;         % Minimum output voltage [V]
Vout_max     = 50;        % Maximum output voltage [V]

Pout_max     = 500;       % Maximum output power [W]
Iout_max     = 10;        % Maximum output current [A]

Efficiency   = 0.95;      % Target efficiency
fsw          = 100e3;     % Switching frequency [Hz]

Vripple_out  = 0.01;      % Allowed output ripple ratio (1%)
IL_ripple_pc = 0.30;      % Inductor ripple current ratio (30%)

Vgate        = 15;        % Gate drive voltage [V]
Qg            = 268e-9;   % MOSFET total gate charge [C]

Current_limit_margin = 1.25;
Inductor_Isat_margin = 1.20;
Inductor_Irms_margin = 1.20;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DERIVED VALUES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Iin_max = Pout_max / (Vin_min * Efficiency);

fprintf('\n=====================================================\n');
fprintf('HIGH POWER BUCK-BOOST\n');
fprintf('=====================================================\n\n');

fprintf('Worst-case input current: %.2f A\n', Iin_max);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DUTY CYCLE ESTIMATES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Boost worst case
D_boost = 1 - (Vin_min / Vout_max);

% Buck worst case
D_buck = Vout_min / Vin_max;

fprintf('\nDuty cycle estimates:\n');
fprintf('Worst-case boost duty cycle: %.3f\n', D_boost);
fprintf('Worst-case buck duty cycle : %.3f\n', D_buck);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% INDUCTOR DESIGN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Worst-case inductor average current
IL_avg = Iin_max;

% Ripple current target
Delta_IL = IL_avg * IL_ripple_pc;

% Boost-mode inductor sizing
L_boost = (Vin_min * D_boost) / (Delta_IL * fsw);

% Buck-mode inductor sizing
L_buck = ((Vin_max - Vout_min) * D_buck) / (Delta_IL * fsw);

% Choose larger value
L_recommended = max(L_boost, L_buck);

fprintf('\n=====================================================\n');
fprintf('INDUCTOR\n');
fprintf('=====================================================\n');

fprintf('Average inductor current : %.2f A\n', IL_avg);
fprintf('Target ripple current    : %.2f A\n', Delta_IL);

fprintf('Boost-mode inductance    : %.2e H\n', L_boost);
fprintf('Buck-mode inductance     : %.2e H\n', L_buck);

fprintf('\nRecommended inductance   : %.2e H\n', L_recommended);
fprintf('Recommended inductance   : %.2f uH\n', L_recommended * 1e6);

% Peak current
IL_peak = IL_avg + (Delta_IL / 2);

% RMS current for triangular ripple
IL_rms = sqrt(IL_avg^2 + (Delta_IL^2 / 12));

% Inductor current capability targets
Inductor_Isat_min = IL_peak * Inductor_Isat_margin;
Inductor_Irms_min = IL_rms * Inductor_Irms_margin;

fprintf('Peak inductor current    : %.2f A\n', IL_peak);
fprintf('Inductor Isat minimum    : %.2f A\n', Inductor_Isat_min);
fprintf('Inductor Irms minimum    : %.2f A\n', Inductor_Irms_min);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% OUTPUT CAPACITOR ESTIMATE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Vripple_abs = Vout_max * Vripple_out;

Cout_est = Delta_IL / (8 * fsw * Vripple_abs);

fprintf('\n=====================================================\n');
fprintf('OUTPUT CAPACITOR ESTIMATE\n');
fprintf('=====================================================\n');

fprintf('Allowed output ripple    : %.3f V\n', Vripple_abs);
fprintf('Estimated Cout minimum   : %.2e F\n', Cout_est);
fprintf('Estimated Cout minimum   : %.2f uF\n', Cout_est * 1e6);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% INPUT CAPACITOR ESTIMATE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Vin_ripple_allowed = 0.02 * Vin_min;

Cin_est = ...
    (Iin_max * D_boost * (1 - D_boost)) / ...
    (fsw * Vin_ripple_allowed);

fprintf('\n=====================================================\n');
fprintf('INPUT CAPACITOR ESTIMATE\n');
fprintf('=====================================================\n');

fprintf('Estimated Cin minimum    : %.2e F\n', Cin_est);
fprintf('Estimated Cin minimum    : %.2f uF\n', Cin_est * 1e6);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PRACTICAL CAPACITOR BANK SIZING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n=====================================================\n');
fprintf('PRACTICAL CAPACITOR BANK SIZING\n');
fprintf('=====================================================\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% INPUT CAPACITOR BANK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Suggested practical scaling factor (typical)
Cin_practical = Cin_est * 4;

% Example capacitor choices
Cin_polymer_each  = 470e-6;   % 470uF polymer
Cin_ceramic_each  = 22e-6;    % 22uF ceramic

% Quantity calculations
Num_Cin_polymer = ceil(Cin_practical / Cin_polymer_each);

% HF ceramics for switching suppression
Num_Cin_ceramic = 4;

Cin_total = ...
    (Num_Cin_polymer * Cin_polymer_each) + ...
    (Num_Cin_ceramic * Cin_ceramic_each);

fprintf('\nINPUT CAPACITOR BANK\n');

fprintf('Practical Cin target     : %.2f uF\n', Cin_practical * 1e6);

fprintf('Aluminium polymer capacitors:\n');
fprintf('  Value each             : %.0f uF\n', Cin_polymer_each * 1e6);
fprintf('  Quantity               : %d\n', Num_Cin_polymer);

fprintf('Ceramic capacitors:\n');
fprintf('  Value each             : %.0f uF\n', Cin_ceramic_each * 1e6);
fprintf('  Quantity               : %d\n', Num_Cin_ceramic);

fprintf('Total estimated Cin      : %.2f uF\n', Cin_total * 1e6);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% OUTPUT CAPACITOR BANK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Practical multiplier
Cout_practical = Cout_est * 6;

% Example capacitor choices
Cout_polymer_each = 330e-6;   % 330uF polymer
Cout_ceramic_each = 22e-6;    % 22uF ceramic

Num_Cout_polymer = ceil(Cout_practical / Cout_polymer_each);

% Ceramics recommended on output
Num_Cout_ceramic = 6;

Cout_total = ...
    (Num_Cout_polymer * Cout_polymer_each) + ...
    (Num_Cout_ceramic * Cout_ceramic_each);

fprintf('\nOUTPUT CAPACITOR BANK\n');

fprintf('Practical Cout target    : %.2f uF\n', Cout_practical * 1e6);

fprintf('Aluminium polymer capacitors:\n');
fprintf('  Value each             : %.0f uF\n', Cout_polymer_each * 1e6);
fprintf('  Quantity               : %d\n', Num_Cout_polymer);

fprintf('Ceramic capacitors:\n');
fprintf('  Value each             : %.0f uF\n', Cout_ceramic_each * 1e6);
fprintf('  Quantity               : %d\n', Num_Cout_ceramic);

fprintf('Total estimated Cout     : %.2f uF\n', Cout_total * 1e6);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% OUTPUT SENSE FILTER NETWORK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\nOUTPUT SENSE NETWORK\n');

Rsns = 2.2;              % Typical small isolation resistor
Cquiet_each = 22e-6;     % Quiet-side ceramics

Num_Cquiet = 2;

Cquiet_total = Num_Cquiet * Cquiet_each;

fprintf('Rsns                     : %.2f Ohm\n', Rsns);
fprintf('Quiet-side ceramics      : %d x %.0f uF\n', ...
        Num_Cquiet, Cquiet_each * 1e6);

fprintf('Quiet-side total cap     : %.2f uF\n', ...
        Cquiet_total * 1e6);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CURRENT SENSE RESISTOR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Ilimit = IL_peak * Current_limit_margin;

Vsense_target = 0.05;   % 50mV target

Rsense = Vsense_target / Ilimit;

Psense = (IL_avg^2) * Rsense;

fprintf('\n=====================================================\n');
fprintf('CURRENT SENSE\n');
fprintf('=====================================================\n');

fprintf('Current limit target     : %.2f A\n', Ilimit);
fprintf('Suggested Rsense         : %.4e Ohm\n', Rsense);
fprintf('Suggested Rsense         : %.3f mOhm\n', Rsense * 1e3);
fprintf('Rsense dissipation       : %.2f W\n', Psense);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MOSFET GATE DRIVE LOSS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% One MOSFET gate-drive power
Pgate_single = Qg * Vgate * fsw;

% Four-switch converter
Pgate_total = 4 * Pgate_single;

fprintf('\n=====================================================\n');
fprintf('GATE DRIVE LOSS\n');
fprintf('=====================================================\n');

fprintf('Single MOSFET gate loss  : %.2f W\n', Pgate_single);
fprintf('Total gate drive loss    : %.2f W\n', Pgate_total);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BOOTSTRAP CAPACITOR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Qdriver_extra = 40e-9;      % Driver + leakage estimate
Qboot_total = Qg + Qdriver_extra;

DeltaV_boot = 1.0;          % Allowable droop

Cboot_min = Qboot_total / DeltaV_boot;

% Practical recommendation
Cboot_recommended = 220e-9;

fprintf('\n=====================================================\n');
fprintf('BOOTSTRAP CAPACITOR\n');
fprintf('=====================================================\n');

fprintf('Minimum theoretical Cboot : %.2e F\n', Cboot_min);
fprintf('Minimum theoretical Cboot : %.2f uF\n', Cboot_min * 1e6);

fprintf('\nRecommended practical values:\n');
fprintf('  Minimum practical       : 100 nF\n');
fprintf('  Recommended             : 220 nF\n');
fprintf('  Conservative            : 470 nF\n');

fprintf('\nSuggested implementation:\n');
fprintf('  1x 220nF X7R 25V/50V ceramic\n');
fprintf('  Place extremely close to driver\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% UVLO RESISTOR DIVIDER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Vuvlo_on = 11.5;
Vuvlo_ref = 1.2;

Ruv2 = 10e3;
Ruv1 = Ruv2 * ((Vuvlo_on / Vuvlo_ref) - 1);

fprintf('\n=====================================================\n');
fprintf('UVLO RESISTORS\n');
fprintf('=====================================================\n');

fprintf('Ruv1: %.2f kOhm\n', Ruv1 / 1e3);
fprintf('Ruv2: %.2f kOhm\n', Ruv2 / 1e3);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SOFT START CAPACITOR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Softstart_time = 20e-3;
Iss = 10e-6;
Vss = 1.2;

Css = (Softstart_time * Iss) / Vss;

fprintf('\n=====================================================\n');
fprintf('SOFT START\n');
fprintf('=====================================================\n');

fprintf('Target soft-start time   : %.2f ms\n', Softstart_time * 1e3);
fprintf('Estimated Css            : %.2e F\n', Css);
fprintf('Estimated Css            : %.2f nF\n', Css * 1e9);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% POWER LOSS ESTIMATE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Ploss_total = Pout_max * (1 - Efficiency);

fprintf('\n=====================================================\n');
fprintf('THERMAL ESTIMATE\n');
fprintf('=====================================================\n');

fprintf('Estimated total losses   : %.2f W\n', Ploss_total);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SUMMARY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n=====================================================\n');
fprintf('SUMMARY\n');
fprintf('=====================================================\n');

fprintf('Recommended inductance   : %.2f uH\n', L_recommended * 1e6);
fprintf('Recommended input cap    : %.2f uF\n', Cin_total * 1e6);
fprintf('Recommended output cap   : %.2f uF\n', Cout_total * 1e6);
fprintf('Recommended Rsense       : %.3f mOhm\n', Rsense * 1e3);
fprintf('Estimated gate drive loss: %.2f W\n', Pgate_total);
fprintf('Estimated total losses   : %.2f W\n', Ploss_total);

fprintf('\nDONE.\n');