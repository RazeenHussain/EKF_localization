% Localization by detection of magnets at known locations in the ground.
% -----
% Usage: 
%    - Set the characteristics of the robot and sensor in 
%      RobotAndSensorDefinition.m
%    - Set noise levels in DefineVariances.m
%    - Set data file name and robot initial position in the present file.
%    - Execute this file.
%    - Then, execute PlotResults.m to get the plots for analysis.
% -----

global period trackGauge rwheel ;
global mainLoopIndex nbLoops ;
global t X P U Uodo Y Qbeta Qgamma Xodom totalTravDistance oTm mTo ;
global dMaha
global measures oPest oPmagnet ;
global xSpacing ySpacing ;
global travDistance nbMagnetsDetected ;

RobotAndSensorDefinition ;
DefineVariances ;

% Set this according to robot initial position.
% Introduce a reasonable error on the wheel radius.
X = [ 0 0 0*pi/180 rwheel-1 rwheel+1 ].' ;    
%Load the data file
dataFile = uigetfile('data/*.txt','Select data file') ;
if isunix ,
    eval(['load data/' , dataFile]) ;
else
    eval(['load data\' , dataFile]) ;
end
dataFile = strrep(dataFile, '.txt', '')
eval(['data = ',dataFile,'; clear ',dataFile]) ;

P = Pinit ; 
Xodom = X(1:3) ;
totalTravDistance = 0 ;

% Skip motionless parts of the data at beginning and end of the experiment
% and return only meaningful data, with wheel rotations in radians.
% Also reduce encoder resolution and frequency according to factors
% set in RobotDefinition.m

[nbLoops,t,qL,qR,sensorReadings] = PreprocessData(data) ;

PrepareVectorsAndMatricesForStorageOfResults ;

wbHandle = waitbar(0,'Computing...') ;

for mainLoopIndex = 2 : nbLoops ,
    
    waitbar(mainLoopIndex/nbLoops) ;

    % Calculate input vector from proprioceptive sensors
    
    % Elementary wheel rotations
    deltaq = [ qR(mainLoopIndex) - qR(mainLoopIndex-1) ; 
               qL(mainLoopIndex) - qL(mainLoopIndex-1) ] ;
    % Elem. transl. and rotation for standard odometry.     
    Uodo = jointToCartesian * deltaq ;  
    
    U = deltaq / period ;
    
    v = (1/2)*( X(4)*U(1) + X(5)*U(2) )             ;
    w = X(4)/trackGauge*U(1) - X(5)/trackGauge*U(2) ;

    % Calculate linear approximation of the system equation

    A = [ 1 0 -0.5*period*sin(X(3))*(X(4)*U(1)+X(5)*U(2)) 0.5*period*U(1)*cos(X(3))    0.5*period*U(2)*cos(X(3)) ;
          0 1  0.5*period*cos(X(3))*(X(4)*U(1)+X(5)*U(2)) 0.5*period*U(1)*sin(X(3))    0.5*period*U(2)*sin(X(3)) ;
          0 0                                           1  (period/trackGauge)*U(1)  -1*(period/trackGauge)*U(2) ;
          0 0                                           0                         1                            0 ;
          0 0                                           0                         0                            1 ] ;
      
    B = [ 0.5*period*X(4)*cos(X(3))   0.5*period*X(5)*cos(X(3)) ;
          0.5*period*X(4)*sin(X(3))   0.5*period*X(5)*sin(X(3)) ;
           (period/trackGauge)*X(4) -1*(period/trackGauge)*X(5) ;
                                  0                           0 ;
                                  0                           0 ] ;
   
    % Predict state (odometry)
    X = EvolutionModel( X , U ) ;
    
    % Error propagation
    P = A*P*(A.') + B*Qbeta*(B.') + Qalpha 
    
    % Vector of measurements. Size is zero if no magnet was detected.
    measures = ExtractMeasurements( sensorReadings(mainLoopIndex) ) ;
    CalculateAndStoreResultsForAnalysis('prediction');
        
    % When two or more magnets are detected simultaneously, they are taken
    % as independant measurements, for the sake of simplicity.
    
    for measNumber = 1 : numel(measures) ,
        
        % Calculate homogeneous transform of the robot with respect to the world frame
        oTm = [ cos(X(3)) -1*sin(X(3)) X(1) ;
                sin(X(3))    cos(X(3)) X(2) ;
                        0            0    1 ] ;
        mTo = inv(oTm) ;
        
        % Measurement vector iX(1:2)n homogeneous coordinates
        Y = [ sensorPosAlongXm ; 
              sensorRes*( measures(measNumber) - sensorOffset ) ;                
              1 ] ;
                
        % Y is the measurement point in robot frame. Transfer to world
        % frame
        oPest = oTm * Y ;
        
        % Which actual magnet is closest to the estimated position?
        oPmagnet = round( oPest ./ [xSpacing ; ySpacing ; 1] ) .* [xSpacing ; ySpacing ; 1] ;

        % The position of the magnet in robot frame is the expected measurement Yhat
        Yhat = mTo * oPmagnet ;
        
        C = [ -1*cos(X(3)) -1*sin(X(3)) ((sin(X(3))*(X(1)-oPmagnet(1)))+(cos(X(3))*(oPmagnet(2)-X(2)))) 0 0 ;
                 sin(X(3)) -1*cos(X(3)) ((sin(X(3))*(X(2)-oPmagnet(2)))+(cos(X(3))*(X(1)-oPmagnet(1)))) 0 0 ] ;
                      
        innov = Y(1:2) - Yhat(1:2) ;   % Not in homogeneous coordinates.
        dMaha = sqrt( innov.' * inv( C*P*C.' + Qgamma) * innov ) ;
        
        CalculateAndStoreResultsForAnalysis( 'measurement' ) ;
        
        if dMaha <= mahaThreshold ,
            K = P * C.' * inv( C*P*C.' + Qgamma) ;
            X = X + K*innov ;
            P = (eye(numel(X)) - K*C) * P ;
            CalculateAndStoreResultsForAnalysis( 'update' ) ;
        end
        
    end

end

close(wbHandle) ;
