global Pinit Qgamma Qbeta mahaThreshold ;

% Uncertainty on initial position of the robot.
sigmaX     = 3 ;          
sigmaY     = 3 ;          
sigmaTheta = 3 *pi/180;   
sigmaRR    = 2 ;          
sigmaRL    = 2 ;
Pinit = diag( [ sigmaX^2 sigmaY^2 sigmaTheta^2 ...
                sigmaRR^2 sigmaRL^2 ] ) ;

% Measurement noise.
sigmaXmeasurement = 24/sqrt(12) ;  
sigmaYmeasurement = 20/sqrt(12) ;  
Qgamma = diag( [sigmaXmeasurement^2 sigmaYmeasurement^2] ) ;

% Input noise
sigmaWheels = 0.05 ;   
Qwheels = sigmaWheels^2 * eye(2) ;
Qbeta   = Qwheels ; 

% State noise
Qalpha = [ 0 0 0    0    0 ;
           0 0 0    0    0 ; 
           0 0 0    0    0 ;
           0 0 0 0.01    0 ;
           0 0 0    0 0.01 ] ;  

% Mahalanobis distance threshold
mahaThreshold = chi2inv(0.9,2) ;  
