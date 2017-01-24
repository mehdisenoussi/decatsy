function grayscaleImageMatrix = make_gaborMat(diffWandG,grey,pixindeg,tiltInDegrees,periodPerDegree,gaborSizeInDeg)
% Create a sine-raised grating according to the given parameters
tiltInRadians = tiltInDegrees * pi / 180; % The tilt of the grating in radians.

% *** To lengthen the period of the grating, increase pixelsPerPeriod.
degreePerPeriod=1/periodPerDegree;
pixelsPerPeriod = degreePerPeriod/pixindeg; % How many pixels will each period/cycle occupy?
spatialFrequency = 1 / pixelsPerPeriod; % How many periods/cycles are there in a pixel?
radiansPerPixel = spatialFrequency * (2 * pi); % = (periods per pixel) * (2 pi radians per period)

% *** If the grating is clipped on the sides, increase widthOfGrid.
gaborDimPix = round(gaborSizeInDeg/pixindeg);
widthOfGrid = gaborDimPix;
halfWidthOfGrid = widthOfGrid / 2;
widthArray = (-halfWidthOfGrid) : halfWidthOfGrid;  % widthArray is used in creating the meshgrid.

% ---------- Image Setup ----------
% Stores the image in a two dimensional matrix.
% Creates a two-dimensional square grid
[x, y] = meshgrid(widthArray, widthArray);

% changing the orientation of the grating
a=cos(tiltInRadians)*radiansPerPixel;
b=sin(tiltInRadians)*radiansPerPixel; 

% Converts meshgrid into a sinusoidal grating, where elements
% along a line with angle theta have the same value and where the
% period of the sinusoid is equal to "pixelsPerPeriod" pixels.
% Note that each entry of gratingMatrix varies between minus one and
% one; -1 <= gratingMatrix(x0, y0)  <= 1
gratingMatrix = sin(a*x+b*y);

% Creates a circular window
circularMaskMatrix = sqrt((x .^ 2) + (y .^ 2));
radius=gaborDimPix/2; fading_pc=.3; fading_ring_size=fading_pc*radius;
% Explanation: You subtract fading_ring_size to radius to get the index 
% where the fading starts, you subtract this index to radii to have a
% matrix where the fading starts at 0
% Divide this matrix by fading_ring_size so that the fading starts at 0
% and ends at 1.
% Multiply by pi/2 so that 0 stays 0 (cos(0)=1) and fading_ring_size
% pix further it gets at pi/2 (cos(pi/2)=0)
% Square it so that it is between [0,1] not sure its the only purpose..
cosMaskMatrix = cos(pi/2 * ((circularMaskMatrix - (radius - ...
    fading_ring_size)) / fading_ring_size )) .^ 2;
cosMaskMatrix(circularMaskMatrix <= (radius - fading_ring_size)) = 1;
cosMaskMatrix(circularMaskMatrix >= radius) = 0;

imageMatrix = (gratingMatrix .* cosMaskMatrix);
grayscaleImageMatrix = grey + diffWandG * imageMatrix;
