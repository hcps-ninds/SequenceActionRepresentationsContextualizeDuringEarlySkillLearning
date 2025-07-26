function sourcePlot(varargin)
% sourcePlot(sourcemodel[,leftHemFeatureData,rightHemFeatureData,cLim,printToPNG])
%
% REQUIRED INPUTS:
%
% sourcemodel - input structure containing surface mesh and labels
%               (Required fields include "pos", "tri", and "brainstructure")
%
% OPTIONAL INPUTS: 
%
% leftHemFeatureData - vector of feature values for all vertices in LEFT
% hemisphere
%
% right HemFeatureData - vector of feature values for all vertices in RIGHT
% hemisphere
%
% cLim - 2-item row vector with colormap scaling limits (mapping range)
%
% printToPNG - boolean T/F input that determine if figure is printed to PNG file
%
% Ethan R Buch 2023 Mar 14
%

%Create color maps
cMapRed = [ones(100,1) linspace(1,0.01,100)' zeros(100,1); ...
           linspace(1,.5,100)' zeros(100,2); ...
           .5*ones(100,1) repmat(linspace(0,.5,100)',1,2)];

cMapBlue = [zeros(100,1) linspace(1,0.01,100)' ones(100,1); ...
            zeros(100,2) linspace(1,.5,100)'; ...
            repmat(linspace(0,.5,100)',1,2) .5*ones(100,1)];
        
if nargin < 0
    error('Requires input source model data.');
elseif nargin > 0
    sourcemodel = varargin{1};
    V = sourcemodel.pos;
    F = sourcemodel.tri;
    
    %Break mesh into left and right hemispheres
    l0 = find(sourcemodel.brainstructure==1,1,'first');
    lN = find(sourcemodel.brainstructure==1,1,'last');
    lV = V(l0:lN,:);
    lF = F(find(sum(F>=l0,2)>0,1,'first'):find(sum(F<=lN,2)>0,1,'last'),:) - l0 + 1;
    
    r0 = find(sourcemodel.brainstructure==2,1,'first');
    rN = find(sourcemodel.brainstructure==2,1,'last');
    rV = V(r0:rN,:);
    rF = F(find(sum(F>=r0,2)>0,1,'first'):find(sum(F<=rN,2)>0,1,'last'),:) - r0 + 1;
    
    %Initialize vectors to be mapped onto mesh 
    leftHemFeatureData = 2*rand(size(lV,1),1)-1; %feature data for left hem (these random values be replaced with real data if passed)
    rightHemFeatureData = 2*rand(size(rV,1),1)-1;
    cLim = [];
    printOutput = false;
end
if nargin > 1
    if isempty(varargin{2})
        leftHemFeatureData = varargin{2};
    end
    if isempty(varargin{3})
        rightHemFeatureData = varargin{3};
    end
end
if nargin > 3
    cLim = varargin{4};
end
if nargin > 4
    printOutput = varargin{4};
end

minDat = min([leftHemFeatureData(:); leftHemFeatureData(:)],[],'omitnan');
maxDat = max([leftHemFeatureData(:); leftHemFeatureData(:)],[],'omitnan');
if minDat <= 0 && maxDat >= 0
    cMap = [cMapBlue; flipud(cMapRed(1:end-1,:))]; %Use this if positive and negative values
elseif minDat >= 0 && maxDat > 0
    cMap = flipud(cMapRed); %Use this if only positive
elseif minDat < 0 && maxData <= 0
    cMap = flipud(cMapBlue); %Use this if only negative
end

if isempty(cLim)
    cLim = prctile([leftHemFeatureData(:); leftHemFeatureData(:)],[5 95]); %Autoset cLim to 5th and 95th %ile if not manually set
end

%Map output measure data to vertex color data
vertCDataL = cmapper(leftHemFeatureData,cMap,cLim,'makima'); 
vertCDataR = cmapper(rightHemFeatureData,cMap,cLim,'makima');

%Create figure object
figure('Units','Normalized','Position',[.05 .05 .9 .9],'ToolBar','none','MenuBar','none','Color','w');

%Title axes
hAxTitle = axes('Position',[0 .9 1 .1],'XLim',[0 1],'YLim',[0 1]);
text(.5,.5,'I am plotting NOISE here','FontName','Arial','FontSize',36,'FontWeight','bold',...
    'HorizontalAlignment','center','VerticalAlignment','top');
axis off;

%Top View axes
hAxTop = axes('Position',[.25 0 .225 1]);
hPL = patch(...
'Faces',lF,...
'Vertices',lV,...
'FaceVertexCData',vertCDataL,...
'FaceColor','interp',...
'EdgeColor','none',...
'BackFaceLighting','unlit');
hPR = patch(...
'Faces',rF,...
'Vertices',rV,...
'FaceVertexCData',vertCDataR,...
'FaceColor','interp',...
'EdgeColor','none',...
'BackFaceLighting','unlit');
axis tight equal off;
hLight(1) = lightangle(90,0);
hLight(2) = lightangle(-90,0);
hLight(3) = lightangle(0,90);
hLight(4) = lightangle(0,-90);
lighting gouraud;
material dull;
colormap(cMap);
caxis(cLim)
view(0,90); % Top view

%Add all other views by copying patch objects from first/top view
%Bottom View axes
hAxBot = axes('Position',[.525 0 .225 1]);
copyobj(get(hAxTop,'Children'),hAxBot);
axis tight equal off;
view(180,-90)

%Left Lat
hAxLHlat = axes('Position',[.025 .5 .225 .5]);
copyobj([hPL hLight],hAxLHlat);
axis tight equal off;
view(-90,0)

%Left Med
hAxLHmed = axes('Position',[0.025 0 .225 .5]);
copyobj([hPL hLight],hAxLHmed);
axis tight equal off;
view(90,0)

%Right Lat
hAxRHlat = axes('Position',[.75 .5 .225 .5]);
copyobj([hPR hLight],hAxRHlat);
axis tight equal off;
view(90,0)

%Right Med
hAxRHmed = axes('Position',[.75 0 .225 .5]);
copyobj([hPR hLight],hAxRHmed);
axis tight equal off;
view(-90,0)

%Colorbar
hAxCB = axes('Position',[.33 .05 .33 .2]);
hCB = colorbar('North');
axis off;
caxis(cLim);
hCB.Label.String = 'Feature importance';
hCB.Label.FontName = 'Arial';
hCB.Label.FontSize = 28;
set(hCB,'Ticks',cLim,'TickDirection','both','FontName','Arial','FontSize',21)

if printOutput %Save figure to 300dpi PNG file
    print(['source_' strrep(datestr(datetime('now')),' ','_') '.png'],'-dpng','-r300');
end

end


%% Internal function that performs direct mapping between data an patch face colors
function cOut = cmapper(varargin)
%
% cOut = cmapper(v,cMap,cLim,[interpType])
%
% REQUIRED INPUTS:
%
% v - input value that you want to return a color for given passed colormap
%       and colormap scaling limits
%
% OPTIONAL INPUTS: 
%
% cmap - colormap (can be a string for built-in matlab colormaps or a Mx3
%           matrix for custom)
%
% clim - colormap scaling limits (mapping range)
%
% interpMeth - Interpolation method that best models colormap (i.e. -
% linear (default), pchip, makima, spline)
%
% Ethan R Buch 2019 Oct 20
%
%
%

if nargin < 1, error('Not enough inputs.  1 is required.'); end

if nargin < 4 
    interpMeth = 'linear'; 
else
    interpMeth = varargin{4};
end

if nargin < 3
    g = groot; 
    if isempty(g.Children)
        error('cLim is a required input if a current axis object does not exist.');
    else
        cLim = caxis(gca);
    end
else   
    cLim = varargin{3};
    if length(cLim)~=2, error('cLim must be a two element vector that specifies the colormapping range.'); end
end

if nargin < 2
    g = groot; 
    if isempty(g.Children)
        error('cMap is a required input if a current axis object does not exist.');
    else
        cMap = colormap(gca);
    end
else
    cMap = varargin{2};
    if isstring(cMap) || ischar(cMap), cMap = eval(['colormap(' cMap '(1000))']); end
    if size(cMap,1)<5, error('Colormap must define at least 5 unique colors.'); end
    if size(cMap,2)~=3, error('Colormap must be RGB (Mx3).'); end
end

v = varargin{1}(:);
v(v < cLim(1)) = cLim(1);
v(v > cLim(2)) = cLim(2);
vMap = linspace(cLim(1),cLim(2),size(cMap,1));

cOut = [interp1(vMap(:),cMap(:,1),v(:),interpMeth), ...
    interp1(vMap(:),cMap(:,2),v(:),interpMeth), ...
    interp1(vMap(:),cMap(:,3),v(:),interpMeth)];
end

