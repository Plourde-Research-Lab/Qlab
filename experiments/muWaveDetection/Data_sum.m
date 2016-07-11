data = load_data();

Data1 = data.data;

data = load_data();

Data2 = data.data;

data = load_data();

Data3 = data.data;

data = load_data();

Data4 = data.data;

data = load_data();

Data5 = data.data;


Sum_Data_Amp = (sqrt(real(Data1).^2 + imag(Data1).^2)) + (sqrt(real(Data2).^2 + imag(Data2).^2)) + (sqrt(real(Data3).^2 + imag(Data3).^2))+ (sqrt(real(Data4).^2 + imag(Data4).^2))+ (sqrt(real(Data5).^2 + imag(Data5).^2));

Ave_Data_Amp = Sum_Data_Amp / 5;

figure; plot (data.xpoints,Ave_Data_Amp)

cal_scale(top);

fitt1

%fitramsey





