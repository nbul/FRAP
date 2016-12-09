clc;
clear variables;
close all;

%% Determening paths and setting folders
currdir = pwd;
addpath(pwd);
filedir = uigetdir();
cd(filedir);

%Folder to save images 
mkdir(filedir,'/FRAP images');
dir1 = [filedir, '/FRAP images'];

%Folder to save raw data
mkdir(filedir,'/Raw data');
dir2 = [filedir, '/Raw data'];

%Folder with coordinates
mkdir(filedir,'/Regions');
dir3 = [filedir, '/Regions'];


Pre_bleach_N1 = inputdlg({'Number of pre-bleach slides:', 'Number of frames'},'Parameters',1,{num2str(0), num2str(0)});
% Redefine extension
Pre_bleach_N = str2double(Pre_bleach_N1{1});
N_frames = str2double(Pre_bleach_N1{2});


files = dir('*.oib');

FRAP_final = zeros(N_frames-Pre_bleach_N,numel(files));
time = 1:390;
for g=1:numel(files)
    ROI_bleach = [1, 2, 3, 4];
    parameters = inputdlg({'Bleach area x_min:', 'y_min:', 'width:', 'height:'},'Parameters',1,{num2str(0), num2str(0),num2str(0),num2str(0)});
    % Redefine extension
    ROI_bleach(1) = str2double(parameters{1});
    ROI_bleach(2) = str2double(parameters{2});
    ROI_bleach(3) = str2double(parameters{3});
    ROI_bleach(4) = str2double(parameters{4});
    
    ROI_control = [1, 2, 3, 4];
    parameters = inputdlg({'Control area x_min:', 'y_min:', 'width:', 'height:'},'Parameters',1,{num2str(0), num2str(0),num2str(0),num2str(0)});
    % Redefine extension
    ROI_control(1) = str2double(parameters{1});
    ROI_control(2) = str2double(parameters{2});
    ROI_control(3) = str2double(parameters{3});
    ROI_control(4) = str2double(parameters{4});
    
    ROI_BG = [1, 2, 3, 4];
    parameters = inputdlg({'Enter x_min:', 'y_min:', 'width:', 'height:'},'Parameters',1,{num2str(0), num2str(0),num2str(0),num2str(0)});
    % Redefine extension
    ROI_BG(1) = str2double(parameters{1});
    ROI_BG(2) = str2double(parameters{2});
    ROI_BG(3) = str2double(parameters{3});
    ROI_BG(4) = str2double(parameters{4});
    
    cd(dir3);
    Otput_regions = ['embryo ', num2str(g), '_regions.csv'];
    data_regions = [ROI_bleach', ROI_control', ROI_BG'];
    headers = {'FRAP', 'Control', 'BG'};
    csvwrite_with_headers(Otput_regions,data_regions, headers);
    cd(filedir);
    
    Image_name = [num2str(g),'.oib'];
    Image = bfopen(Image_name);
    
    Series = Image{1,1};
    seriesCount = size(Series, 1); %display size to check type of file
    Series_t1= Series{1,1};
    
    FRAP1 = zeros(seriesCount,1);
    Control = zeros(seriesCount,1);
    BG = zeros(seriesCount,1);
    
    for q=1:seriesCount
        Image_time = Series{q,1};
        Image_FRAP = imcrop(Image_time, ROI_bleach);
        FRAP1(q,1) = mean2(Image_FRAP);
        %FRAP_1D(q,:) = mean(Image_FRAP,2);
        Image_Control = imcrop(Image_time, ROI_control);
        Control(q,1) = mean2(Image_Control);
        Image_BG = imcrop(Image_time, ROI_BG);
        BG(q,1) = mean2(Image_BG);
    end
    
    %imshow(FRAP_1D,[min(min(FRAP_1D)) max(max(FRAP_1D))])
    
    FRAP_corr = FRAP1- BG;
    Control_corr = Control - BG;
    
    FRAP_norm = FRAP_corr./Control_corr;
    
    Pre_bleach = mean(FRAP_norm(1:10));
    
    FRAP_norm = FRAP_norm/Pre_bleach;
    
    FRAP_norm = FRAP_norm(Pre_bleach_N+1:seriesCount);
    
    FRAP_final(:,g) = (FRAP_norm-FRAP_norm(1))/(Pre_bleach-FRAP_norm(1));
   
    
    image3 = figure;
    set(axes,'FontSize',16);
    plot(time,FRAP_final(:,g), 'o', 'Color','b', 'MarkerSize',4, 'MarkerFaceColor', 'b');
    title('FRAP', 'fontsize',18,'fontweight','b')
    xlabel('time', 'fontsize',16,'fontweight','b');
    ylabel('Fluorescence intensity', 'fontsize',16,'fontweight','b');
    text_control = ['embryo ', num2str(g)];
    text(300, 0.2, text_control, 'HorizontalAlignment','right', 'fontsize',14, 'fontweight','b');
    axis([0 400 0 1.2]);
    
    cd(dir1);
    Otput_Image = ['embryo ', num2str(g), '.tif'];
    print(image3, '-dtiff', '-r300', Otput_Image);
    
    cd(dir2);
    Otput_data = ['embryo ', num2str(g), '.csv'];
    data = [FRAP1, Control, BG];
    headers = {'FRAP', 'Control', 'BG'};
    csvwrite_with_headers(Otput_data,data, headers);
    cd(filedir);
    close all;
end

csvwrite('Result.csv', FRAP_final);

cd(currdir);
clc;
clear variables