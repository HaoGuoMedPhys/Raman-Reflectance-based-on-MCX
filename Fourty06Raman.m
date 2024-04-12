%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MCXLAB - Monte Carlo eXtreme for MATLAB/Octave by Qianqina Fang
%
% In this example, we simulate a 4-layer brain model using MCXLAB.
% We will investigate the differences between the solutions with and 
% witout boundary reflections (both external and internal) and show
% you how to display and analyze the resulting data.
%
% This file is part of Monte Carlo eXtreme (MCX) URL:http://mcx.sf.net
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% only clear cfg to avoid accidentally clearing other useful data
clear cfg;

%% preparing the input data
% set seed to make the simulation repeatible
cfg.seed=hex2dec('623F9A9E'); 
cfg.unitinmm=5e-4;
cfg.nphoton=1e8;
cfg.maxdetphoton=1e7;
% define a 4 layer structure
cfg.vol=ones(120,120,260);

for i=1:6:120
    for j=1:6:120
        for k=21:6:260
            cfg.vol(i:i+5,j:j+5,k:k+5)=randi([2,6],1);
            
        end
    end
end

cfg.vol=uint8(cfg.vol);

% define the source position
cfg.srcpos=[60 60 20];
cfg.srcdir=[0 0 1];
% define the detector position
cfg.detpos=[60 60 0 60];
% use the optical properties defined at
% format: [mua(1/mm) mus(1/mm) g n]

cfg.prop=[0 0 1 1            % medium 0: the environment
          0.07 35.6 0.95 1.366   % medium 1: water
          0.005364 329.2 0.96623 1.4747
          0.005364 329.2 0.96623 1.4747% medium 2: fat
          0.3 3.7 0.91 1.475
          0.3 3.7 0.91 1.475
          0.3 3.7 0.91 1.475];     % medium 3: liver


% time-domain simulation parameters
cfg.tstart=0;
cfg.tend=1e-10;
cfg.tstep=1e-10;

% GPU thread configuration
% other simulation parameters

cfg.isreflect=0;
cfg.autopilot=1;
cfg.gpuid=1;

cfg.debuglevel='TP';

cfg.srctype='disk';
cfg.srcparam1=[10 10 0 0 ];
%% run the simulation

[fluence,detphoton,vol]=mcxlab(cfg);
%% plotting the result

PhotonNumber=size(detphoton.data);
PhotonNumber=PhotonNumber(2);
%% begin setup for Raman emmission launches
Rcfg.nphoton=1e7;
Rcfg.maxdetphoton=1e7;
Rcfg.vol=cfg.vol;
Rcfg.prop=cfg.prop;
Rcfg.srctype='weighed';
Rcfg.unitinmm=5e-4;
Rcfg.srcpattern = double(fluence.data)/1e12;
Rcfg.srcpos=[1 1 1];
Rcfg.srcdir=[0 0 1];
Rcfg.srcparam1=[size(cfg.vol,1) size(cfg.vol,2) size(cfg.vol,3)];
% define the detector position
Rcfg.detpos=[60 60 0 60];
%%time-gate for Raman emission launches 
Rcfg.tstart=0;
Rcfg.tend=1e-10; 
Rcfg.tstep=1e-10;
%%set srcpattern to results from fluence
Rcfg.isreflect=0;
Rcfg.autopilot=1;
Rcfg.gpuid=1;

[flu,det]=mcxlab(Rcfg);

RamanPhotonNumber=size(det.data);
RamanPhotonNumber=RamanPhotonNumber(2);
