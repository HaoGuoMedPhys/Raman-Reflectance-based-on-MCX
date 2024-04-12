% Overlay contour on  kv-triggered images.
% V1.0 Hao Guo October 2023
% Part 1 - create and display 3d masks of ROI contour in reference coordinate



% Extract numbers of slices in x y z directions
xvoxelsize=0.5;
yvoxelsize=0.5;
zvoxelsize=0.5;

% Extract sizes of each voxel; unit: mm
xspacing=0.5;
yspacing=0.5;
zspacing=0.5;


% Ranges of spatial locations of planning CT
xlim=[-60,60];
ylim=[-60,60];
zlim=[0,130];
referenceInfo  = imref3d([xvoxelsize,yvoxelsize,zvoxelsize],xlim,ylim,zlim);%Set up 3d reference coordinate

% 3d viwer
% viewer = viewer3d(BackgroundColor="white",BackgroundGradient="off",CameraZoom=1.5); % 3d viewer
% maskDisp = volshow(rtMask,Parent=viewer);
viewer = viewer3d(BackgroundColor="white",BackgroundGradient="off",CameraZoom=1.5);
volDisp = volshow(cfg.vol,Parent=viewer, ...
    RenderingStyle="GradientOpacity",GradientOpacityValue=0.8, ...
    Alphamap=linspace(0,1,512),OverlayAlphamap=0.8);