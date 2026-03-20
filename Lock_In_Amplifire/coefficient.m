clc;
clear;
close all;

%% ================= PARAMETERS =================
fs = 10e6;        % Sampling frequency (10 MHz)
fc = 2e3;         % Cutoff frequency (2 kHz)
num_taps = 64;    % Number of taps (must match Vivado)

order = num_taps - 1;

%% ================= FIR DESIGN =================
b = fir1(order, fc/(fs/2));   % Low-pass FIR

%% ================= NORMALIZATION =================
% Ensure unity gain at DC
b = b / sum(b);

%% ================= PLOT RESPONSE =================
figure;
freqz(b,1,1024,fs);
title('FIR Low Pass Filter Response');

%% ================= FLOAT COEFFICIENT FILE =================
fid = fopen('fir_coeff_float.txt','w');
for i = 1:length(b)
    fprintf(fid, '%.10f\n', b(i));
end
fclose(fid);

%% ================= FIXED-POINT CONVERSION =================
% Q1.15 format (16-bit signed)
scale = 2^15;

b_fixed = round(b * scale);

% Saturation protection
b_fixed(b_fixed > 32767) = 32767;
b_fixed(b_fixed < -32768) = -32768;

%% ================= SAVE FIXED COEFF (TXT) =================
fid = fopen('fir_coeff_fixed.txt','w');
for i = 1:length(b_fixed)
    fprintf(fid, '%d\n', b_fixed(i));
end
fclose(fid);

%% ================= GENERATE COE FILE (VIVADO) =================
fid = fopen('fir_coeff.coe','w');

fprintf(fid, 'memory_initialization_radix=10;\n');
fprintf(fid, 'memory_initialization_vector=\n');

for i = 1:length(b_fixed)
    if i == length(b_fixed)
        fprintf(fid, '%d;\n', b_fixed(i));
    else
        fprintf(fid, '%d,\n', b_fixed(i));
    end
end

fclose(fid);

%% ================= DISPLAY INFO =================
disp('FIR design completed!');
disp('Files generated:');
disp('1. fir_coeff_float.txt  (for reference)');
disp('2. fir_coeff_fixed.txt  (for manual use)');
disp('3. fir_coeff.coe        (USE THIS IN VIVADO)');